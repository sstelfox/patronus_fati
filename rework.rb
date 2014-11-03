require 'json'
require 'openssl'
require 'socket'
require 'timeout'
require 'thread'

require 'hiredis'
require 'redis'

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

# Encapsulated logic for transforming the MessageModels into coherent models,
# allowing for the extraction of relevant information from the provided
# MessageModel to be aggregated and stored in a useful way.
module RedisModels
  class AccessPoint
    # Take a Ssid message and extract anything we can from it it for storage
    # in Redis. This only stores information relevant to the access point
    # itself, the other model types need to pull their own information out of
    # this same message.
    #
    # @param [MessageModels::Ssid] ssid A copy of the Ssid message
    #   received.
    # @return [RedisModels::AccessPoint,Nil]
    def self.process_ssid_message(ssid)
      return unless %w(beacon probe_response).include?(ssid.type)

      access_point = find_or_new(ssid.mac)
      access_point.last_seen = Time.now.to_i
      access_point.save
      access_point
    end

    def self.find(mac)
      mac = mac.tr(':', '')
      if $redis.exists("access_points:#{mac}")
        new(JSON.parse($redis.get("access_points:#{mac}")))
      end
    end

    def self.find_or_new(mac)
      find(mac) || new(mac: mac)
    end

    def self.valid_keys
      [:first_seen, :last_seen, :bssid, :mac, :channel, :signal_dbm]
    end

    def initialize(attrs)
      attrs.each do |key, val|
        self.send(:"#{key}=", val) if self.class.valid_keys.include?(key.to_sym)
      end

      self.first_seen ||= Time.now
      self.last_seen ||= Time.now
    end

    attr_reader :first_seen, :last_seen
    attr_accessor :bssid, :channel, :mac, :signal_dbm

    # Set the first seen value to the provided one. This allows you to set an
    # earlier first time than one we have recorded but not a newer value. This
    # allows for kismet server restarts without corrupting collected data.
    #
    # @param [Time,Fixnum] val A time object, or the unix timestamp of the
    #   first time this access poitn was seen
    def first_seen=(val)
      val = Time.at(val) if val.is_a?(Fixnum)
      @attributes[:first_seen] = val if first_seen.nil? || val < first_seen
    end

    def last_seen=(val)
      val = Time.at(val) if val.is_a?(Fixnum)
      @attributes[:last_seen] = val if last_seen.nil? || val > last_seen
    end

    def save_attributes
      {
        bssid: bssid,
        channel: channel,
        first_seen: first_seen.to_i,
        last_seen: last_seen.to_i,
        mac: mac,
        signal_dbm: signal_dbm
      }
    end

    def save_key
      "access_points:#{mac.tr(':', '')}"
    end

    def save
      $redis.pipelined do
        $redis.set(save_key, JSON.generate(save_attributes))
        $redis.zadd("access_points:", Time.now.to_i, mac.tr(':', ''))
      end
      cleanup
    end

    # Clean out any access points that haven't been seen in a while and it's
    # submodels...
    def cleanup
      # TODO
    end
  end

  class Ssid
    # Take a Ssid message and extract anything we can from it it for storage
    # in Redis. This only stores information relevant to the SSID itself the
    # other model types need to pull their own information out of this same
    # message.
    #
    # @param [MessageModels::Ssid] ssid A copy of the Ssid message
    #   received.
    # @return [RedisModels::Ssid,Nil]
    def self.process_ssid_message(ssid)
      return unless %w(beacon probe_response).include?(ssid.type)

      access_point = find_or_new(ssid.mac)
      ssid = find_or_new(access_point, ssid.ssid)

      ssid.last_seen = Time.now.to_i
      ssid.save

      ssid
    end

    # Clean out any SSIDs on a provided access point that haven't been seen in
    # a while as well as the master SSID mapping list.
    def self.cleanup
      # TODO
    end

    def self.digest_name(name)
      OpenSSL::Digest::SHA1.hexdigest(name)
    end

    def self.find(access_point, ssid)
      key = "#{access_point.save_key}:ssids:#{digest_name(ssid)}"
      new(JSON.parse($redis.get(key))) if $redis.exists(key)
    end

    def self.find_or_new(access_point, ssid)
      find(access_point, ssid) || new(bssid: access_point.bssid, ssid: ssid)
    end

    def self.valid_keys
      [:bssid, :ssid, :cryptset, :cloaked, :first_seen, :last_seen, :max_rate]
    end

    def initialize(attrs)
      update(attrs)

      self.first_seen ||= Time.now
      self.last_seen ||= Time.now
    end

    attr_reader :first_seen, :last_seen
    attr_accessor :bssid, :ssid, :cryptset, :cloaked, :max_rate

    def access_point
      @access_point ||= RedisModels::AccessPoint.find(bssid)
    end

    def digest
      @digest ||= self.class.digest(ssid)
    end

    # Set the first seen value to the provided one. This allows you to set an
    # earlier first time than one we have recorded but not a newer value. This
    # allows for kismet server restarts without corrupting collected data.
    #
    # @param [Time,Fixnum] val A time object, or the unix timestamp of the
    #   first time this access poitn was seen
    def first_seen=(val)
      val = Time.at(val) if val.is_a?(Fixnum)
      @attributes[:first_seen] = val if first_seen.nil? || val < first_seen
    end

    def last_seen=(val)
      val = Time.at(val) if val.is_a?(Fixnum)
      @attributes[:last_seen] = val if last_seen.nil? || val > last_seen
    end

    def save_attributes
      {
        bssid: bssid,
        ssid: ssid,
        cryptset: cryptset,
        cloaked: cloaked,
        max_rate: max_rate,
        first_seen: first_seen.to_i,
        last_seen: last_seen.to_i
      }
    end

    def save_key
      "#{access_point.save_key}:ssids#{self.class.digest(ssid)}"
    end

    def save
      $redis.pipelined do
        $redis.set(save_key, JSON.generate(save_attributes))
        $redis.zadd("#{access_point.save_key}:ssids:", Time.now.to_i, digest)
        $redis.zadd("ssids:", Time.now.to_i, digest)
        $redis.sadd("ssids:#{digest}", access_point.save_key)
      end
      self.class.cleanup(access_point)
    end

    def update(attrs)
      attrs.each do |key, val|
        self.send(:"#{key}=", val) if self.class.valid_keys.include?(key.to_sym)
      end
    end
  end

  class Client
  end
end

$redis = Redis.new(url: 'redis://:FVH4dgugJR6HU3MJAYa4KAjhG0QAoMxc@10.13.37.124:6379/0')

begin
  Timeout.timeout(10) do
    conn = TCPSocket.new('10.13.37.124', 2501)
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
      when 'MessageModels::Battery'
        # Not necessarily valuable to me, but might be interesting to expose
        # through the API since I've already got the information.
        $redis.set('power', JSON.generate(obj.attributes))
      when 'MessageModels::Capability'
        # The capability detection for the capability command is broken. It
        # returns the name of the command followed by the capabilities but the
        # result of a request ignores that it also sends back the name of the
        # command. We don't want to mess up our parsing so we work around it by
        # ignoring these messages.
        next if obj.name == 'CAPABILITY'

        target_cap = MessageModels.const_get(obj.name.downcase.capitalize)
        target_cap.supported_keys = obj.capabilities.split(',').map(&:to_sym)

        keys_to_enable = target_cap.enabled_keys.map(&:to_s).join(',')
        write_queue << "ENABLE #{obj.name} #{keys_to_enable}"
      when 'MessageModels::Channel'
        # Noisy, need to remove this for testing...
      when 'MessageModels::Client'
        client_key = "clients:#{obj.mac}"

        # If we already have information about this client pull it in for the
        # basis of the merge.
        base_hash = ($redis.exists(client_key) ? JSON.parse($redis.get(client_key), symbolize_names: true) : {first_seen: obj.firsttime})

        client = {
          channel: obj.channel,
          frequencies: obj.freqmhz,
          last_seen: obj.lasttime,
          mac: obj.mac
        }

        # TODO: GPS if have a fix
        # TODO: Packet counts?
        # Signal strengths are handled by Clisrc messages...

        $redis.pipelined do
          $redis.zadd('clients:', Time.now.to_i, obj.mac)
          $redis.set(client_key, JSON.generate(base_hash.merge(client)))
        end

        # TODO: Client cleanup
      when 'MessageModels::Gps'
        # Currently we don't need to do anything with GPS...
      when 'MessageModels::Info'
        $redis.set('info', JSON.generate(obj.attributes))
      when 'MessageModels::Protocols'
        obj.protocols.split(',').each do |p|
          write_queue << "CAPABILITY #{p}"
        end
      when 'MessageModels::Time'
        $redis.set('time', JSON.generate(timestamp: obj.timesec))
      when 'MessageModels::Source'
        # Store relevant information about our scanning source...
        $redis.pipelined do
          $redis.zadd('sources:', Time.now.to_i, obj.uuid)
          $redis.hmset("sources:#{obj.uuid}", *obj.attributes.to_a.flatten)
        end

        expiring_keys = $redis.zrangebyscore('sources:', 0, (Time.now.to_i - 3600))
        unless expiring_keys.empty?
          puts "Expiring Source UUIDs: #{expiring_keys.join(",")}"
          $redis.pipelined do
            expiring_keys.each { |k| $redis.del("sources:#{k}") }
            $redis.zremrangebyscore("sources:", 0, (Time.now.to_i - 3600))
          end
        end
      when 'MessageModels::Ssid'
        ap = RedisModels::AccessPoint.process_ssid_message(obj)
        ssid = RedisModels::Ssid.process_ssid_message(obj)

        case obj.type
        when 'probe_response'
          $redis.pipelined do
            # Record this BSSID was broadcasting this SSID with the specified values
            $redis.zadd("aps:#{obj.mac}:ssids:", Time.now.to_i, digest)
            $redis.set(ssid_key, JSON.generate(base_hash.merge(
              ssid: obj.ssid, cryptset: obj.cryptset, cloaked: obj.cloaked,
              last_seen: obj.lasttime, max_rate: obj.maxrate
            )))

            # Also record that this SSID was broadcast by this BSSID
            $redis.zadd("ssids:", Time.now.to_i, digest)
            $redis.zadd("ssids:#{digest}", Time.now.to_i, obj.mac)
          end

          # TODO: SSID / APs cleanup
        when 'probe_request'
          unless obj.ssid.nil? || obj.ssid.empty?
            $redis.zadd('clients:', Time.now.to_i, obj.mac)
            $redis.zadd("clients:#{obj.mac}:probes", Time.now.to_i, obj.ssid)

            # TODO: Client cleanup
          end
        when 'beacon'
          digest = OpenSSL::Digest::SHA1.hexdigest(obj.ssid)

          # If we already have information about this SSID pull it in for the
          # basis of the merge.
          ssid_key = "#{ap.save_key}:ssids:#{digest}"
          base_hash = ($redis.exists(ssid_key) ? JSON.parse($redis.get(ssid_key), symbolize_names: true) : {first_seen: obj.firsttime})

          $redis.pipelined do
            $redis.zadd("#{ap.save_key}:ssids:", Time.now.to_i, digest)
            $redis.set(ssid_key, JSON.generate(base_hash.merge(
              ssid: obj.ssid, cryptset: obj.cryptset, cloaked: obj.cloaked,
              last_seen: obj.lasttime, max_rate: obj.maxrate,
              beacon_rate: obj.beaconrate
            )))
          end

          # TODO: SSID / APs cleanup
        else
          puts obj.class
          puts obj.attributes
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
