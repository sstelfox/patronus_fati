module PatronusFati::DataModels
  # Number of seconds before we consider an access point as offline
  AP_EXPIRATION = 300

  class AccessPoint
    include DataMapper::Resource

    property :id, Serial

    property :bssid,   String,  :length => 17, :required => true, :unique => true
    property :type,    String,  :required => true
    property :channel, Integer, :required => true

    property :last_seen_at, Time, :default => Proc.new { Time.now }

    has n, :broadcasts,   :constraint => :destroy
    has n, :clients,      :through    => :connections
    has n, :connections,  :constraint => :destroy,
                          :child_key  => :access_point_id
    has n, :ssids,        :through    => :broadcasts

    belongs_to :mac, :required => false
    before :save do
      self.mac = Mac.first_or_create(mac: bssid)
    end

    def self.active
      all(:last_seen_at.gte => Time.at(Time.now.to_i - AP_EXPIRATION))
    end

    def self.inactive
      all(:last_seen_at.lt => Time.at(Time.now.to_i - AP_EXPIRATION))
    end

    def active_broadcasts
      broadcasts.active
    end

    def active_connections
      connections.active
    end

    def connected_clients
      active_connections.clients
    end

    def current_ssids
      active_broadcasts.ssids
    end

    def full_state
      {
        last_seen_at: last_seen_at,

        bssid: bssid,
        type: type,
        channel: channel,
        vendor: mac.vendor,

        clients: clients.map(&:bssid),
        connected_clients: connected_clients.map(&:bssid),

        ssids: ssids.map(&:full_state),
        current_ssids: current_ssids.map(&:full_state)
      }
    end
  end
end
