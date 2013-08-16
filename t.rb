
require 'json'
require 'singleton'
require 'socket'
require 'strscan'

SERVER_RESPONSE = %r{
  (?<header> [A-Z]+){0}
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

class PendingCommands
  include Singleton

  def initialize
    @command_list = {}
  end

  def add_command(id, command)
    @command_list[id.to_s] = command
  end

  def commands
    @command_list
  end

  def succeed(id)
    # For now we're going to succeed silently
    @command_list.delete(id.to_s)
  end

  def fail(id, msg = "")
    puts "WARNING: Command '#{@command_list[id]}' failed with error: #{msg}"
    @command_list.delete(id.to_s)
  end
end

class ServerInfo
  include Singleton

  def initialize
    @info = {}
  end

  def merge(data)
    @info.deep_merge!(data)
  end

  def data
    @info
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
    PendingCommands.instance.succeed(break_data_into_segments(hsh["data"])[0])

    {}
  when "CAPABILITY"
    segs = break_data_into_segments(hsh["data"])

    { "protocols" => { segs[0].downcase => segs[1].split(",") }}
  when "ERROR"
    segs = break_data_into_segments(hsh["data"])
    PendingCommands.instance.fail(segs.shift, segs.join(" "))

    {}
  when "KISMET"
    # Initial server informational line
    segments = break_data_into_segments(hsh["data"])
    segments[1] = Time.at(segments[1].to_i)
    fields = ["version", "start_time", "server_name", "build_revision", "command_id"]

    { "server_info" => Hash[fields.zip(segments)] }
  when "PROTOCOLS"
    status_protocols = ["ack", "capability", "error", "kismet", "protocols",
      "terminate", "time"]

    available_protocols = hsh["data"].split(",").map(&:strip).map(&:downcase)
    available_protocols.reject! { |r| status_protocols.include?(r) }
    available_protocols = available_protocols.each_with_object({}) { |p, o| o[p] = nil }
    
    { "protocols" => available_protocols, "discover_capabilities" => true }
  when "STATUS"
    puts "LOG: #{hsh['data']}"
    {}
  when "TERMINATE"
    # Time to die...
    puts "Server closed the connection"
    {}
  when "TIME"
    { "server_info" => { "last_timestamp" => Time.at(hsh["data"].to_i) } }
  else
    # Check and see if we're dealing with a data protocol message
    if (ServerInfo.instance.data["protocols"] || {}).keys.include?(hsh["header"].downcase)
      keys = ServerInfo.instance.data["protocols"][hsh["header"].downcase]
      data = break_data_into_segments(hsh['data'])[0...keys.count]

      puts Hash[hsh['header'].downcase, Hash[keys.zip(data)]]

      {}
    else
      raise "Unrecognized server response processed #{hsh['header']}."
      {}
    end
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

def send_command(socket, id, command)
  PendingCommands.instance.add_command(id, command)
  socket.puts("!#{id} #{command}")
end

s = TCPSocket.new('127.0.0.1', 2501)
command_id = 1

while l = s.readline
  ServerInfo.instance.merge(process_server_response(l))

  # If we've received a protocols packet from the server, refresh all the
  # capabilities on each of the protocols from the server.
  if ServerInfo.instance.data["discover_capabilities"]
    ServerInfo.instance.data["protocols"].keys.each do |p|
      send_command(s, command_id, "CAPABILITY #{p.upcase}")
      command_id += 1
    end

    ServerInfo.instance.data.delete("discover_capabilities")
    ServerInfo.instance.data["enable_capabilities"] = true
  end

  # If we aren't waiting on the response of any commands and we need to enable
  # capabilities... do it...
  if ServerInfo.instance.data["enable_capabilities"] && PendingCommands.instance.commands.empty?
    useful_protocols = [ "status", "info", "ssid", "bssid", "source", "gps",
      "battery", "client", "bssidsrc" ]

    useful_protocols.each do |k|
      caps = ServerInfo.instance.data["protocols"][k]
      send_command(s, command_id, "ENABLE #{k.upcase} #{caps.join(",")}")
      command_id += 1
    end

    # This enables all messages
    #ServerInfo.instance.data["protocols"].each do |k, v|
    #  send_command(s, command_id, "ENABLE #{k.upcase} #{v.join(",")}")
    #  command_id += 1
    #end

    ServerInfo.instance.data.delete("enable_capabilities")
  end

  # When in debug...
  #puts JSON.generate(ServerInfo.instance.data)
  #puts
end

# The first time is information about the server:
#   *KISMET: 0.0.0 1376572253 \x01procrustes.internal.0x378.net\x01 \x01\x01 0 \n
# The second line is a list of protocols supported by the server
#   *PROTOCOLS: KISMET,ERROR,ACK,PROTOCOLS,CAPABILITY,TERMINATE,TIME,PACKET,
#     STATUS,SOURCE,ALERT,PHYMAP,DEVICE,DEVICEDONE,TRACKINFO,DEVTAG,DOT11SSID,
#     DOT11DEVICE,DOT11CLIENT,PLUGIN,GPS,BSSID,SSID,CLIENT,BSSIDSRC,CLISRC,
#     NETTAG,CLITAG,REMOVE,CHANNEL,SPECTRUM,INFO,BATTERY,CRITFAIL\n

s.close

