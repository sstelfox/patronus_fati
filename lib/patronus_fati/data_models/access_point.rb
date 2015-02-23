module PatronusFati::DataModels
  class AccessPoint
    include DataMapper::Resource

    property  :id,              Serial
    property  :bssid,           String,   :length   => 17, :required => true, :unique => true
    property  :type,            String,   :required => true
    property  :channel,         Integer,  :required => true
    property  :reported_status, String,   :default  => 'active'

    property  :last_seen_at,    Integer,  :default => Proc.new { Time.now.to_i }

    has n, :clients,      :through    => :connections
    has n, :connections,  :constraint => :destroy,
                          :child_key  => :access_point_id
    has n, :ssids,        :constraint => :destroy

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

    def disconnect_clients!
      connections.destroy
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
  end
end
