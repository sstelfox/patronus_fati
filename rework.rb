#!/usr/bin/env ruby

$:.push(File.expand_path('lib', __FILE__))

require 'patronus_fati'

include PatronusFati

class NullObject < BasicObject
  def method_missing(*args, &block)
    self
  end
end

def exception_logger(tag)
  yield
rescue => e
  puts "(#{tag}) Rescued from error: #{e.message}"
  puts e.backtrace
end

# We receive some messages before we specifically request the abilities of the
# server, when this happens we'll attempt to map the data using the default
# attribute ordering that was provided by the Kismet server this client was
# coded against, this may not be entirely accurate, but will become accurate
# before we receive any meaningful data.
def parse_msg(line)
  unless (resp = SERVER_MESSAGE.match(line))
    fail(ArgumentError, "Received weird message: #{line}")
  end

  h = Hash[resp.names.zip(resp.captures)]
  h['data'] = h['data'].scan(DATA_DELIMITER)
    .map { |a, b| (a || b).tr("\x01", '') }

  unless MessageModels.const_defined?(h['header'].downcase.capitalize.to_sym)
    return NullObject.new
  end

  cap_class = MessageModels.const_get(h['header'].downcase.capitalize.to_sym)
  unless cap_class
    fail(ArgumentError, 'Message received had unknown message type: ' +
         h['header'])
  end

  if cap_class.enabled_keys.empty?
    cap_class.new(Hash[cap_class.attribute_keys.zip(h['data'])])
  else
    cap_class.new(Hash[cap_class.enabled_keys.zip(h['data'])])
  end
end

connection = PatronusFati::Connection.new('127.0.0.1', 2501)
connection.connect

exception_logger('process') do
  while (line = connection.read_queue.pop)
    obj = parse_msg(line)

    case obj.class.to_s
    when 'MessageModels::Ack'
      # Yeah they're coming in but baby I know I'm doing right by you, you
      # don't have to keep telling me.
    when 'MessageModels::Capability'
      # The capability detection for the capability command is broken. It
      # returns the name of the command followed by the capabilities but the
      # result of a request ignores that it also sends back the name of the
      # command. We don't want to mess up our parsing so we work around it by
      # ignoring these messages.
      next if obj.name == 'CAPABILITY'
      next unless MessageModels.const_defined?(obj.name.downcase.capitalize)

      target_cap = MessageModels.const_get(obj.name.downcase.capitalize)
      target_cap.supported_keys = obj.capabilities.split(',').map(&:to_sym)

      keys_to_enable = target_cap.enabled_keys.map(&:to_s).join(',')
      connection.write("ENABLE #{obj.name} #{keys_to_enable}")
    when 'MessageModels::Protocols'
      obj.protocols.split(',').each do |p|
        connection.write("CAPABILITY #{p}")
      end
    else
      puts obj.class
      puts obj.attributes
    end
  end
end

connection.disconnect

read_thread.kill
write_thread.kill
