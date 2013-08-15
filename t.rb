
require 'json'
require 'socket'
require 'strscan'

SERVER_RESPONSE = %r{
  (?<header> .+){0}
  (?<data> .+){0}

  ^\*\g<header>:\s+\g<data>$
}x

SERVER_DATA = %r{
  (?<string> \S+){0}
  (?<string_with_space> \x01(\S+\b?){0,}\x01){0}

  (\g<string_with_space>|\g<string>)
}x

# The core Hash class
# This adds the deep_merge method to this core class which is used to join nested hashes
class Hash

  # Non destructive version of deep_merge using a dup
  #
  # @param [Hash] the hash to be merged with
  # @returns [Hash] A copy of a new hash merging the hash
  # this was called on and the param hash
  def deep_merge(other_hash)
    dup.deep_merge!(other_hash)
  end

  # Recusively merges hashes into each other. Any value that is not a Hash will
  # be overridden with the value in the other hash.
  #
  # @param [Hash] the hash to be merged with
  # @returns [Hash] A copy of itself with the new hash merged in
  def deep_merge!(other)
    raise ArgumentError unless other.is_a?(Hash)

    other.each do |k, v|
      self[k] = (self[k].is_a?(Hash) && self[k].is_a?(Hash)) ? self[k].deep_merge(v) : v
    end

    self
  end
end

def unimplemented_message(type, message)
  puts "Received unimplemented message #{type}: #{message}"
  {}
end

def process_server_response(resp)
  hsh = extract_response(resp)

  case hsh["header"]
  when "ACK"
    unimplemented_message(hsh["header"], hsh["data"])
  when "CAPABILITY"
    unimplemented_message(hsh["header"], hsh["data"])
  when "ERROR"
    unimplemented_message(hsh["header"], hsh["data"])
  when "KISMET"
    # Initial server informational line
    segments = break_data_into_segments(hsh["data"])
    segments[1] = Time.at(segments[1].to_i)
    fields = ["version", "start_time", "server_name", "build_revision", "command_id"]
    
    { "server_info" => Hash[fields.zip(segments)] }
  when "PROTOCOLS"
    available_protocols = hsh["data"].split(",").map(&:strip).map(&:downcase)
    
    { "protocols" => available_protocols.each_with_object({}) { |p, o| o[p] = {} } }
  when "TERMINATE"
    unimplemented_message(hsh["header"], hsh["data"])
  when "TIME"
    { "server_info" => { "last_timestamp" => Time.at(hsh["data"].to_i) } }
  else
    raise "Unrecognized server response processed."
  end
end

def break_data_into_segments(data)
  strscan = StringScanner.new(data)
  results = []

  while e = strscan.scan_until(SERVER_DATA)
    results << e.scan(/[[:print:]]/).join.strip
  end

  results
end

def extract_response(resp)
  return unless resp =~ SERVER_RESPONSE
  Hash[SERVER_RESPONSE.names.zip(SERVER_RESPONSE.match(resp).captures)]
end

s = TCPSocket.new('127.0.0.1', 2501)

info = {}

while l = s.readline
  info.deep_merge!(process_server_response(l))

  puts JSON.generate(info)
  puts
end

# The first time is information about the server:
#   *KISMET: 0.0.0 1376572253 \x01procrustes.internal.0x378.net\x01 \x01\x01 0 \n
# The second line is a list of protocols supported by the server
#   *PROTOCOLS: KISMET,ERROR,ACK,PROTOCOLS,CAPABILITY,TERMINATE,TIME,PACKET,STATUS,SOURCE,ALERT,PHYMAP,DEVICE,DEVICEDONE,TRACKINFO,DEVTAG,DOT11SSID,DOT11DEVICE,DOT11CLIENT,PLUGIN,GPS,BSSID,SSID,CLIENT,BSSIDSRC,CLISRC,NETTAG,CLITAG,REMOVE,CHANNEL,SPECTRUM,INFO,BATTERY,CRITFAIL\n

s.close
