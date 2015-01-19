#!/usr/bin/env ruby

$:.push(File.expand_path(File.join('..', 'lib'), __FILE__))

require 'patronus_fati'

def exception_logger(tag)
  yield
rescue => e
  puts "(#{tag}) Rescued from error: #{e.message}"
  puts e.backtrace
end

connection = PatronusFati::Connection.new('10.13.37.128', 2501)
connection.connect

exception_logger('process') do
  while (line = connection.read_queue.pop)
    obj = PatronusFati::MessageParser.parse(line)

    case obj.class.to_s
    when 'PatronusFati::MessageModels::Ack'
      # Yeah they're coming in but baby I know I'm doing right by you, you
      # don't have to keep telling me.
    when 'PatronusFati::MessageModels::Battery'
      # Power info isn't accurate and not valuable for the aggregation
      # information.
    when 'PatronusFati::MessageModels::Capability'
      # The capability detection for the capability command is broken. It
      # returns the name of the command followed by the capabilities but the
      # result of a request ignores that it also sends back the name of the
      # command. We don't want to mess up our parsing so we work around it by
      # ignoring these messages.
      next if obj.name == 'CAPABILITY'
      next unless PatronusFati::MessageModels.const_defined?(obj.name.downcase.capitalize)

      target_cap = PatronusFati::MessageModels.const_get(obj.name.downcase.capitalize)
      target_cap.supported_keys = obj.capabilities.split(',').map(&:to_sym)

      keys_to_enable = target_cap.enabled_keys.map(&:to_s).join(',')
      connection.write("ENABLE #{obj.name} #{keys_to_enable}")
    when 'PatronusFati::MessageModels::Gpsd'
      # Specific source locations aren't going to be valuable right now
    when 'PatronusFati::MessageModels::Info'
      # Not caring about statistical info right now
    when 'PatronusFati::MessageModels::Protocols'
      obj.protocols.split(',').each do |p|
        connection.write("CAPABILITY #{p}")
      end
    when 'PatronusFati::MessageModels::Time'
      # Not caring about time right now...
    else
      puts obj.class
      puts obj.attributes
    end
  end
end

connection.disconnect
