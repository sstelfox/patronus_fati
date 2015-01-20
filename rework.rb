#!/usr/bin/env ruby

$:.push(File.expand_path(File.join('..', 'lib'), __FILE__))

require 'patronus_fati'

def exception_logger(tag)
  yield
rescue Interrupt
  puts 'Closing'
rescue => e
  puts "(#{tag}) Rescued from error: #{e.message}"
  puts e.backtrace
end

connection = PatronusFati::Connection.new('10.13.37.128', 2501)
connection.connect

exception_logger('process') do
  while (line = connection.read_queue.pop)
    next unless (obj = PatronusFati::MessageParser.parse(line))
    responses = PatronusFati::MessageProcessor.handle(obj)

    Array(responses).each do |msg|
      connection.write(msg)
    end
  end
end

connection.disconnect
