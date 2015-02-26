module PatronusFati::DataModels
  class AccessPoint
    include DataMapper::Resource

    include PatronusFati::DataModels::ExpirationAttributes
    include PatronusFati::DataModels::ReportedAttributes

    property  :id,                Serial

    property  :bssid,             String, :length   => 17,
                                          :required => true,
                                          :unique   => true

    property  :channel,           Integer
    property  :max_seen_rate,     Integer
    property  :type,              String, :required => true

    property  :duplicate_iv_pkts, Integer,  :default => 0
    property  :crypt_packets,     Integer,  :default => 0
    property  :data_packets,      Integer,  :default => 0
    property  :data_size,         Integer,  :default => 0

    property  :fragments,         Integer,  :default => 0
    property  :retries,           Integer,  :default => 0

    property  :range_ip,          String
    property  :netmask,           String
    property  :gateway_ip,        String


    property  :signal_dbm,        Integer

    has n, :clients,        :through    => :connections
    has n, :connections,    :constraint => :destroy,
                            :child_key  => :access_point_id
    has n, :ssids,          :constraint => :destroy
    has n, :ap_frequencies, :constraint => :destroy

    belongs_to :mac, :required => false
    before :save do
      self.mac = Mac.first_or_create(mac: bssid)
    end

    def self.current_expiration_threshold
      Time.now.to_i - PatronusFati::AP_EXPIRATION
    end

    def connected_clients
      connections.active.clients
    end

    def current_ssids
      ssids.active
    end

    def disconnect_clients!
      connections.connected.map(&:disconnect!)
    end

    def full_state
      blacklisted_keys = %w(id last_seen_at reported_status)
      attributes.reject { |k, v| blacklisted_keys.include?(k) || v.nil? }.merge(vendor: mac.vendor)
    end

    def update_frequencies(freq_hsh)
      freq_hsh.each do |freq, packet_count|
        f = ap_frequencies.first_or_create({mhz: freq}, {packet_count: packet_count})
        f.update({packet_count: packet_count})
      end
    end
  end
end
