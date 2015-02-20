#!/usr/bin/env ruby

STDIN.sync = true
STDOUT.sync = true

require 'json'

base_msg = {
  'data'    => nil,
  'options' => {},
  'source'  => 'patronus_fati',
  'type'    => 'wireless',
  'version' => '0.8.0'
}

while (line = STDIN.readline)
  puts JSON.generate(base_msg.merge('data' => JSON.parse(line)))
  STDOUT.flush
end
