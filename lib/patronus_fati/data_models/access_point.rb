module PatronusFati::DataModels
  class AccessPoint
    include DataMapper::Resource

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

    property  :last_seen_at,      Integer,  :default  => Proc.new { Time.now.to_i }
    property  :reported_status,   String,   :default  => 'active'

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

    def self.active
      all(:last_seen_at.gte => (Time.now.to_i - PatronusFati::AP_EXPIRATION))
    end

    def self.inactive
      all(:last_seen_at.lt => (Time.now.to_i - PatronusFati::AP_EXPIRATION))
    end

    def self.reported_active
      all(:reported_status => 'active')
    end

    def self.reported_expired
      all(:reported_status => 'expired')
    end

    def connected_clients
      connections.unexpired.clients
    end

    def current_ssids
      ssids.active
    end

    def disconnect_clients!(reason = nil)
      connections.each do |conn|
        conn.reason = reason
        conn.destroy
      end
    end

    def full_state
      {
        bssid: bssid,
        type: type,
        channel: channel,
        vendor: mac.vendor,

        clients: connected_clients.map(&:bssid),
        ssids: current_ssids.map(&:full_state)
      }
    end

    def seen!(time = Time.now.to_i)
      update(last_seen_at: time, reported_status: 'active')
    end

    def update_frequencies(freq_hsh)
      freq_hsh.each do |freq, packet_count|
        f = ap_frequencies.first_or_create({mhz: freq}, {packet_count: packet_count})
        f.update({packet_count: packet_count})
      end
    end
  end
end
