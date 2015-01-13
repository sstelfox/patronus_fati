


DATA_DELIMITER = /(\x01[^\x01]+\x01)|(\S+)/

BSSID_TYPE_MAP = {
  0   => 'infrastructure',
  1   => 'adhoc',
  2   => 'probe',
  3   => 'turbocell',
  4   => 'data',
  255 => 'mixed',
  256 => 'remove'
}

# 'DS' is short for distribution system, it has something to do with packet
# domains 'BSS' (the prefix on BSSID) but it's clear that identifier is more
# than what I thought it was...
CLIENT_TYPE_MAP = {
  0 => 'unknown',
  1 => 'from_ds',
  2 => 'to_ds',
  3 => 'inter_ds',
  4 => 'established',
  5 => 'adhoc',
  6 => 'remove'
}

# This map was retrieved from a combination of the packet_ieee80211.h header
# file and dumpfile_netxml.cc source in the kismet git repo.
SSID_CRYPT_MAP = {
  0 => 'None',
  1 => 'Unknown',
  (1 << 1) => 'WEP',
  (1 << 2) => 'Layer3',
  (1 << 3) => 'WEP40',
  (1 << 4) => 'WEP104',
  (1 << 5) => 'WPA+TKIP',
  (1 << 6) => 'WPA', # Appears deprecated but still in the kismet source
  (1 << 7) => 'WPA+PSK',
  (1 << 8) => 'WPA+AES-OCB',
  (1 << 9) => 'WPA+AES-CCM',
  (1 << 10) => 'WPA Migration Mode',
  (1 << 11) => 'WPA+EAP', # Not a value that shows up in kismet exports... Bonus?
  (1 << 12) => 'WPA+LEAP',
  (1 << 13) => 'WPA+TTLS',
  (1 << 14) => 'WPA+TLS',
  (1 << 15) => 'WPA+PEAP',
  (1 << 20) => 'ISAKMP',
  (1 << 21) => 'PPTP',
  (1 << 22) => 'Fortress',
  (1 << 23) => 'Keyguard',
  (1 << 24) => 'Unknown Protected',
  (1 << 25) => 'Unknown Non-WEP',
  (1 << 26) => 'WPS'
}

SSID_TYPE_MAP = {
  0 => 'beacon',
  1 => 'probe_response',
  2 => 'probe_request',
  3 => 'file'
}

SERVER_MESSAGE = /
  (?<header> [A-Z]+){0}
  (?<data> .+){0}

  ^\*\g<header>:\s+\g<data>$
/x

conn = nil

def exception_logger(tag)
  yield
rescue => e
  puts "(#{tag}) Rescued from error: #{e.message}"
  puts e.backtrace
end

# Namespace holder for models representing the raw messages we receive back
# from the kismet server.
module MessageModels
  # Class generator similar to a struct but allows for using a hash as an
  # unordered initializer. This was designed to work as an initializer for
  # capability classes and thus has a few additional methods written in to
  # support this functionality.
  module CapStruct
    # Creates a new dynamic class with the provided attributes.
    #
    # @param [Array<Symbol>] args The list of attributes of getters and
    #   setters.
    def self.new(*args)
      Class.new do
        @attributes_keys = args.map(&:to_sym).dup.freeze
        @supported_keys = []

        # Any unspecified data filter will default to just returning the same
        # value passed in.
        @data_filters = Hash.new(Proc.new { |i| i })

        # Returns the keys that are valid for this class (effectively it's
        # attributes)
        #
        # @return [Array<Symbol>]
        def self.attribute_keys
          @attributes_keys
        end

        # Call and return the resulting value of the data filter requested.
        #
        # @param [Symbol] attr
        # @param [Object] value
        # @return [Object]
        def self.data_filter(attr, value)
          @data_filters[attr].call(value)
        end

        # Set the data filter to the provided block.
        #
        # @param [Symbol] attr
        def self.set_data_filter(*attr)
          blk = Proc.new
          Array(attr).each { |a| @data_filters[a] = blk }
        end

        # Return the intersection of our known attribute keys and the keys that
        # the server has claimed to support.
        #
        # @return [Array<Symbol>]
        def self.enabled_keys
          attribute_keys & supported_keys
        end

        # Return the keys the server has claimed to support.
        #
        # @return [Array<Symbol>]
        def self.supported_keys
          @supported_keys
        end

        # Set the keys supported by the server.
        #
        # @param [Array<Symbol>] sk
        def self.supported_keys=(sk)
          @supported_keys = sk
        end

        attr_reader :attributes

        # Configure and setup the instance with all the valid parameters for
        # the dynamic class.
        #
        # @attrs [Symbol=>Object] attrs
        def initialize(attrs)
          @attributes = {}

          attrs.each do |k, v|
            if self.class.attribute_keys.include?(k.to_sym)
              @attributes[k.to_sym] = self.class.data_filter(k.to_sym, v)
            end
          end
        end

        # Define all the appropriate setters and getters for this dynamic class.
        args.each do |a|
          define_method(a.to_sym) { @attributes[a.to_sym] }
          define_method("#{a}=".to_sym) { |val| self.class.data_filter(a.to_sym, val) }
        end
      end
    end
  end

  # @note The ordering of the attributes is actually important, as these are
  #   the default orderings provided by the server I was developing against.
  #   The casing of the name is also important as the best we can automatically
  #   do from the header information is a downcase and capitalize.

  Ack = CapStruct.new(:cmdid, :text)

  Alert = CapStruct.new(
    :sec, :usec, :header, :bssid, :source, :dest, :other, :channel, :text
  )
  Alert.set_data_filter(:bssid, :source, :dest, :other) { |val| val.downcase }
  Alert.set_data_filter(:sec, :usec, :channel) { |val| val.to_i }

  Battery = CapStruct.new(:percentage, :charging, :ac, :remaining)
  Battery.set_data_filter(:percentage, :charging, :ac, :remaining) { |val| val.to_i }

  Bssid = CapStruct.new(
    :bssid, :type, :llcpackets, :datapackets, :cryptpackets, :manuf, :channel,
    :firsttime, :lasttime, :atype, :rangeip, :netmaskip, :gatewayip, :gpsfixed,
    :minlat, :minlon, :minalt, :minspd, :maxlat, :maxlon, :maxalt, :maxspd,
    :signal_dbm, :noise_dbm, :minsignal_dbm, :minnoise_dbm, :maxsignal_dbm,
    :maxnoise_dbm, :signal_rssi, :noise_rssi, :minsignal_rssi, :minnoise_rssi,
    :maxsignal_rssi, :maxnoise_rssi, :bestlat, :bestlon, :bestalt, :agglat,
    :agglon, :aggalt, :aggpoints, :datasize, :turbocellnid, :turbocellmode,
    :turbocellsat, :carrierset, :maxseenrate, :encodingset, :decrypted,
    :dupeivpackets, :bsstimestamp, :cdpdevice, :cdpport, :fragments, :retries,
    :newpackets, :freqmhz, :datacryptset
  )
  Bssid.set_data_filter(:bssid) { |val| val.downcase }
  Bssid.set_data_filter(:llcpackets, :datapackets, :cryptpackets, :channel,
                        :firsttime, :lasttime, :atype, :gpsfixed, :minlat,
                        :minlon, :minalt, :minspd, :maxlat, :maxlon, :maxalt,
                        :maxspd, :signal_dbm, :noise_dbm, :minsignal_dbm,
                        :minnoise_dbm, :maxsignal_dbm, :maxnoise_dbm,
                        :signal_rssi, :noise_rssi, :minsignal_rssi,
                        :minnoise_rssi, :maxsignal_rssi, :maxnoise_rssi,
                        :bestlat, :bestlon, :bestalt, :agglat, :agglon,
                        :aggalt, :aggpoints, :datasize, :turbocellnid,
                        :turbocellmode, :turbocellsat, :carrierset,
                        :maxseenrate, :encodingset, :decrypted, :dupeivpackets,
                        :bsstimestamp, :fragments, :retries, :newpackets) { |val| val.to_i }

  # Attempt to map the returned BSSID type to one we know about it and
  # convert it to a string. In the event we don't know it will leave this as
  # an integer field.
  #
  # @param [String] bssid_type The string is actually an integer value in
  #   numeric form (this is how it's received from the network).
  Bssid.set_data_filter(:type) { |val| BSSID_TYPE_MAP[val.to_i] || val.to_i }

  Bssidsrc = CapStruct.new(
    :bssid, :uuid, :lasttime, :numpackets, :signal_dbm, :noise_dbm,
    :minsignal_dbm, :minnoise_dbm, :maxsignal_dbm, :maxnoise_dbm, :signal_rssi,
    :noise_rssi, :minsignal_rssi, :minnoise_rssi, :maxsignal_rssi,
    :maxnoise_rssi
  )
  Bssidsrc.set_data_filter(:bssid) { |val| val.downcase }

  Btscandev = CapStruct.new(
    :bdaddr, :name, :class, :firsttime, :lasttime, :packets, :gpsfixed,
    :minlat, :minlon, :minalt, :minspd, :maxlat, :maxlon, :maxalt, :maxspd,
    :agglat, :agglon, :aggalt, :aggpoints
  )
  Btscandev.set_data_filter(:bdaddr) { |val| val.downcase }

  Capability = CapStruct.new(:name, :capabilities)

  Channel = CapStruct.new(
    :channel, :time_on, :packets, :packetsdelta, :usecused, :bytes,
    :bytesdelta, :networks, :maxsignal_dbm, :maxsignal_rssi, :maxnoise_dbm,
    :maxnoise_rssi, :activenetworks
  )

  Client = CapStruct.new(
    :bssid, :mac, :type, :firsttime, :lasttime, :manuf, :llcpackets,
    :datapackets, :cryptpackets, :gpsfixed, :minlat, :minlon, :minalt, :minspd,
    :maxlat, :maxlon, :maxalt, :maxspd, :agglat, :agglon, :aggalt, :aggpoints,
    :signal_dbm, :noise_dbm, :minsignal_dbm, :minnoise_dbm, :maxsignal_dbm,
    :maxnoise_dbm, :signal_rssi, :noise_rssi, :minsignal_rssi, :minnoise_rssi,
    :maxsignal_rssi, :maxnoise_rssi, :bestlat, :bestlon, :bestalt, :atype, :ip,
    :gatewayip, :datasize, :maxseenrate, :encodingset, :carrierset, :decrypted,
    :channel, :fragments, :retries, :newpackets, :freqmhz, :cdpdevice,
    :cdpport, :dot11d, :dhcphost, :dhcpvendor, :datacryptset
  )
  Client.set_data_filter(:bssid, :mac) { |val| val.downcase }

  # Attempt to map the returned client type to one we know about it and convert
  # it to a string. In the event we don't know it will leave this as an integer
  # field.
  #
  # @param [String] client_type The string is actually an integer value in
  #   numeric form (this is how it's received from the network).
  Client.set_data_filter(:type) { |val| CLIENT_TYPE_MAP[val.to_i] || val.to_i }
  Client.set_data_filter(:firsttime, :lasttime, :llcpackets, :datapackets,
                         :cryptpackets, :minlat, :minlon, :minalt, :minspd,
                         :maxlat, :maxlon, :maxalt, :maxspd, :agglat, :agglon,
                         :aggalt, :aggpoints, :signal_dbm, :noise_dbm,
                         :minsignal_dbm, :minnoise_dbm, :maxsignal_dbm,
                         :maxnoise_dbm, :signal_rssi, :noise_rssi,
                         :minsignal_rssi, :minnoise_rssi, :maxsignal_rssi,
                         :maxnoise_rssi, :bestlat, :bestlon, :bestalt, :atype,
                         :datasize, :maxseenrate, :encodingset, :carrierset,
                         :decrypted, :channel, :fragments, :retries,
                         :newpackets) { |val| val.to_i }
  Client.set_data_filter(:gpsfixed) { |val| val.to_i == 1 }

  Clisrc = CapStruct.new(
    :bssid, :mac, :uuid, :lasttime, :numpackets, :signal_dbm, :noise_dbm,
    :minsignal_dbm, :minnoise_dbm, :maxsignal_dbm, :maxnoise_dbm, :signal_rssi,
    :noise_rssi, :minsignal_rssi, :minnoise_rssi, :maxsignal_rssi,
    :maxnoise_rssi
  )
  Clisrc.set_data_filter(:bssid, :mac) { |val| val.downcase }
  Clisrc.set_data_filter(:lasttime, :numpackets, :signal_dbm, :noise_dbm,
                         :minsignal_dbm, :minnoise_dbm, :maxsignal_dbm,
                         :maxnoise_dbm, :signal_rssi, :noise_rssi,
                         :minsignal_rssi, :minnoise_rssi, :maxsignal_rssi,
                         :maxnoise_rssi) { |val| val.to_i }

  Clitag = CapStruct.new(:bssid, :mac, :tag, :value)
  Clitag.set_data_filter(:bssid, :mac) { |val| val.downcase }

  Common = CapStruct.new(
    :phytype, :macaddr, :firsttime, :lasttime, :packets, :llcpackets,
    :errorpackets, :datapackets, :cryptpackets, :datasize, :newpackets,
    :channel, :frequency, :freqmhz, :gpsfixed, :minlat, :minlon, :minalt,
    :minspd, :maxlat, :maxlon, :maxalt, :maxspd, :signaldbm, :noisedbm,
    :minsignaldbm, :minnoisedbm, :signalrssi, :noiserssi, :minsignalrssi,
    :minnoiserssi, :maxsignalrssi, :maxnoiserssi, :bestlat, :bestlon, :bestalt,
    :agglat, :agglon, :aggalt, :aggpoints
  )
  Common.set_data_filter(:macaddr) { |val| val.downcase }

  Critfail = CapStruct.new(:id, :time, :message)
  Error = CapStruct.new(:cmdid, :text)

  Gps = CapStruct.new(
    :lat, :lon, :alt, :spd, :heading, :fix, :satinfo, :hdop, :vdop, :connected
  )

  Kismet = CapStruct.new(
    :version, :starttime, :servername, :dumpfiles, :uid
  )

  Info = CapStruct.new(
    :networks, :packets, :crypt, :noise, :dropped, :rate, :filtered, :clients,
    :llcpackets, :datapackets, :numsources, :numerrorsources
  )
  Info.set_data_filter(:networks, :packets, :crypt, :noise, :dropped, :rate,
                       :filtered, :clients, :llcpackets, :datapackets,
                       :numsources, :numerrorsources) { |val| val.to_i }

  Nettag = CapStruct.new(:bssid, :tag, :value)
  Nettag.set_data_filter(:bssid) { |val| val.downcase }

  Packet = CapStruct.new(
    :type, :subtype, :timesec, :encrypted, :weak, :beaconrate, :sourcemac,
    :destmac, :bssid, :ssid, :prototype, :sourceip, :destip, :sourceport,
    :destport, :nbtype, :nbsource, :sourcename
  )
  Packet.set_data_filter(:bssid, :destmac, :sourcemac) { |val| val.downcase }

  Plugin = CapStruct.new(
    :filename, :name, :version, :description, :unloadable, :root
  )
  Plugin.set_data_filter(:unloadable, :root) { |val| val.to_i }

  Protocols = CapStruct.new(:protocols)

  Remove = CapStruct.new(:bssid)
  Remove.set_data_filter(:bssid) { |val| val.downcase }

  Spectrum = CapStruct.new(
    :devname, :amp_offset_mdbm, :amp_res_mdbm, :rssi_max, :start_khz, :res_hz,
    :num_samples, :samples
  )

  Source = CapStruct.new(
    :interface, :type, :username, :channel, :uuid, :packets, :hop, :velocity,
    :dwell, :hop_time_sec, :hop_time_usec
  )
  Source.set_data_filter(:channel, :dwell, :hop_time_sec, :hop_time_usec, :hop,
                         :packets, :velocity) { |val| val.to_i }

  Ssid = CapStruct.new(
    :mac, :checksum, :type, :ssid, :beaconinfo, :cryptset, :cloaked,
    :firsttime, :lasttime, :maxrate, :beaconrate
  )
  Ssid.set_data_filter(:mac) { |val| val.downcase }
  Ssid.set_data_filter(:checksum, :firsttime, :lasttime, :maxrate, :beaconrate) { |val| val.to_i }
  Ssid.set_data_filter(:cloaked) { |val| val.to_i == 1 }
  Ssid.set_data_filter(:cryptset) do |val|
    val = val.to_i
    next [SSID_CRYPT_MAP[0]] if val == 0
    SSID_CRYPT_MAP.select { |k, _| (k & val) != 0 }.map { |_, v| v }
  end

  # Attempt to map the returned SSID type to one we know about it and convert
  # it to a string. In the event we don't know it will leave this as an integer
  # field.
  #
  # @param [String] ssid_type The string is actually an integer value in
  #   numeric form (this is how it's received from the network).
  Ssid.set_data_filter(:type) { |val| SSID_TYPE_MAP[val.to_i] || val.to_i }

  Status = CapStruct.new(:text, :flags)

  String = CapStruct.new(:bssid, :source, :dest, :string)
  String.set_data_filter(:bssid) { |val| val.downcase }

  Terminate = CapStruct.new(:text)
  Time = CapStruct.new(:timesec)

  Trackinfo = CapStruct.new(
    :devices, :packets, :datapackets, :cryptpackets, :errorpackets,
    :filterpackets, :packetrate
  )

  Wepkey = CapStruct.new(:origin, :bssid, :key, :encrypted, :failed)
  Wepkey.set_data_filter(:bssid) { |val| val.downcase }
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
