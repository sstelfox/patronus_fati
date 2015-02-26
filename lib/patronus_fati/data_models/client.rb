module PatronusFati::DataModels
  class Client
    include DataMapper::Resource

    include PatronusFati::DataModels::ExpirationAttributes
    include PatronusFati::DataModels::ReportedAttributes

    property  :id,              Serial
    property  :bssid,           String,   :length => 17, :unique => true
    property  :channel,         Integer

    property  :crypt_packets,   Integer,  :default => 0
    property  :data_packets,    Integer,  :default => 0
    property  :data_size,       Integer,  :default => 0
    property  :fragments,       Integer,  :default => 0
    property  :retries,         Integer,  :default => 0

    property  :max_seen_rate,   Integer
    property  :signal_dbm,      Integer

    property  :ip,              String
    property  :gateway_ip,      String
    property  :dhcp_host,       String,   :length => 64

    has n, :connections,    :constraint => :destroy
    has n, :access_points,  :through    => :connections

    has n, :client_frequencies, :constraint => :destroy
    has n, :probes,             :constraint => :destroy

    belongs_to :mac, :required => false
    before :save do
      self.mac = Mac.first_or_create(mac: bssid)
    end

    def self.current_expiration_threshold
      Time.now.to_i - PatronusFati::CLIENT_EXPIRATION
    end

    def connected_access_points
      connections.active.access_points
    end

    def disconnect!
      connections.connected.map(&:disconnect!)
    end

    def full_state
      {
        bssid: bssid,
        vendor: mac.vendor,

        connected_access_points: connected_access_points.map(&:bssid).uniq,
        probes: probes.map(&:essid),
      }
    end

    def update_frequencies(freq_hsh)
      freq_hsh.each do |freq, packet_count|
        f = client_frequencies.first_or_create({mhz: freq}, {packet_count: packet_count})
        f.update({packet_count: packet_count})
      end
    end
  end
end
