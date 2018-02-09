#!/usr/bin/env ruby

require 'json'

def deep_diff(a, b)
  (a.keys | b.keys).each_with_object({}) do |k, diff|
    if a[k] != b[k]
      if a[k].is_a?(Hash) && b[k].is_a?(Hash)
        diff[k] = deep_diff(a[k], b[k])
      else
        diff[k] = [a[k], b[k]]
      end
    end
    diff
  end
end

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
  next if %w(alert both connection sync).include?(msg['asset_type'])
  next if msg['event_type'] == 'sync'

  stats[:relevant_messages] += 1
  asset_type = msg['asset_type']

  data = msg['data']
  data['event_type'] = msg['event_type']
  data['last_dbm'] = msg['diagnostics']['last_dbm']
  #data['timestamp'] = msg['timestamp']

  if data['ssids']
    ssids = data.delete('ssids')
    data['ssids'] = ssids.map do |s|
      s.reject { |k, _| %w(last_visible).include?(k) }
    end
  end

  bssid = data.delete('bssid')

  message_breakdown[asset_type][bssid] ||= []
  message_breakdown[asset_type][bssid] << data
end
file.close

changes = []

message_breakdown.each do |type, data|
  data.each do |bssid, msgs|
    next if msgs.count <= 2
    stats[:abberations] += msgs.count

    change_string = msgs.map { |m| m['event_type'][0] }.join
    info = {
      bssid: bssid,
      msgs_count: msgs.count,
      initial_state: msgs[0],
      change_string: change_string,
      deltas: []
    }

    1.upto(msgs.count - 1) do |i|
      info[:deltas] << deep_diff(msgs[i - 1], msgs[i])
    end

    changes << info
  end
end

puts JSON.pretty_generate(changes)
puts stats.inspect
