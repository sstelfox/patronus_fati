module PatronusFati::DataModels
  class AccessPoint
    include DataMapper::Resource

    property :id, Serial

    property :bssid,   String,  :length => 17, :required => true, :unique => true
    property :type,    String,  :required => true
    property :channel, Integer, :required => true

    property :last_seen_at, Time, :default => Proc.new { Time.now }

    has n, :broadcasts,         :constraint => :destroy
    has n, :current_broadcasts, :model      => 'Broadcast',
                                :constraint => :destroy,
                                :child_key  => :access_point_id,
                                :last_seen_at.gte => Proc.new { Time.at(Time.now.to_i - SSID_EXPIRATION) }

    has n, :ssids,         :through => :broadcasts
    has n, :current_ssids, :model   => 'Ssid',
                           :through => :current_broadcasts,
                           :via     => :ssid

    has n, :connections,        :constraint => :destroy,
                                :child_key  => :access_point_id
    has n, :active_connections, :model      => 'Connection',
                                :constraint => :destroy,
                                :child_key  => :access_point_id,
                                :disconnected_at => nil

    has n, :clients,            :through => :connections
    has n, :connected_clients,  :model   => 'Client',
                                :through => :active_connections,
                                :via     => :client

    belongs_to :mac, :required => false
    before :save do
      self.mac = Mac.first_or_create(mac: bssid)
    end

    def full_state
      {
        id: id,
        last_seen_at: last_seen_at,

        bssid: bssid,
        type: type,
        channel: channel,

        clients: clients.map(&:bssid),
        connected_clients: connected_clients(&:bssid),

        ssids: ssids.map(&:attributes),
        current_ssids: current_ssids.map(&:attributes)
      }
    end
  end
end
