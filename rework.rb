#!/usr/bin/env ruby

$:.push(File.expand_path(File.join(File.dirname(__FILE__), 'lib')))

require 'patronus_fati'

include PatronusFati

conn = nil

def exception_logger(tag)
  yield
rescue => e
  puts "(#{tag}) Rescued from error: #{e.message}"
  puts e.backtrace
end

module MessageModels
  # @note The ordering of the attributes is actually important, as these are
  #   the default orderings provided by the server I was developing against.
  #   The casing of the name is also important as the best we can automatically
  #   do from the header information is a downcase and capitalize.
end

begin
  Timeout.timeout(10) do
    conn = TCPSocket.new('127.0.0.1', 2501)
  end
rescue Timeout::Error
  puts 'Timed out while attempting to connect to kismet'
  exit 1
end

read_queue = Queue.new
write_queue = Queue.new

read_thread = Thread.new do
  puts 'Read thread starting...'

  exception_logger('read') do
    begin
      while (line = conn.readline)
        read_queue << line
      end
    rescue Timeout::Error
      puts 'Connection timed out.'
      exit 1
    rescue EOFError
      puts 'Lost connection.'
      exit 1
    rescue => e
      puts "Received error: #{e.message}"
      exit 1
    end
  end
end

write_thread = Thread.new do
  puts 'Write thread starting...'

  exception_logger('write') do
    count = 0
    while (msg = write_queue.pop)
      conn.write("!#{count} #{msg}\r\n")
      count += 1
    end
  end
end

class NullObject < BasicObject
  def method_missing(*args, &block)
    self
  end
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

process_thread = Thread.new do
  puts 'Processing thread starting...'

  exception_logger('process') do
    while (line = read_queue.pop)
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
        write_queue << "ENABLE #{obj.name} #{keys_to_enable}"
      when 'MessageModels::Protocols'
        obj.protocols.split(',').each do |p|
          write_queue << "CAPABILITY #{p}"
        end
      else
        puts obj.class
        puts obj.attributes
      end
    end
  end
end

process_thread.join
read_thread.kill
write_thread.kill
