#!/usr/bin/env ruby

require 'json'

unless ARGV[0]
  puts 'Must provide a file as the first argument...'
  exit 1
end

unless File.exists?(ARGV[0]) && File.readable?(ARGV[0])
  puts 'Provided filename either doesn\'t exist or isn\'t readable.'
  exit 2
end

message_breakdown = {
  'access_point' => {},
  'client' => {}
}

stats = {
  relevant_messages: 0,
  abberations: 0
}

file = File.open(ARGV[0])
file.each_line do |line|
  msg = JSON.parse(line)
  next if %w(both connection sync).include?(msg['asset_type'])
  next if msg['event_type'] == 'sync'

  stats[:relevant_messages] += 1
  asset_type = msg['asset_type']

  data = msg['data']
  data['event_type'] = msg['event_type']
  data['last_dbm'] = msg['diagnostics']['last_dbm']
  data['timestamp'] = msg['timestamp']

  bssid = data.delete('bssid')

  message_breakdown[asset_type][bssid] ||= []
  message_breakdown[asset_type][bssid] << data
end
file.close

message_count_breakdown = {}

message_breakdown.each do |type, data|
  message_count_breakdown[type] = {}

  data.each do |bssid, msgs|
    next if msgs.count <= 2
    stats[:abberations] += msgs.count

    change_string = msgs.map { |m| m['event_type'][0] }.join

    message_count_breakdown[type][change_string] ||= []
    message_count_breakdown[type][change_string] << bssid
  end
end

puts JSON.pretty_generate(message_count_breakdown)
puts stats.inspect
