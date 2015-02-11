module PatronusFati::DataModels
  class Client
    include DataMapper::Resource

    property :id,           Serial
    property :bssid,        String, :length => 17, :unique => true
    property :last_seen_at, Time, { :default => Proc.new { Time.now } }

    has n, :connections,        :constraint => :destroy
    has n, :active_connections, :model      => 'Connection',
                                :constraint => :destroy,
                                :child_key  => :client_id,
                                :disconnected_at => nil

    has n, :access_points,         :through => :connections
    has n, :current_access_points, :model   => 'AccessPoint',
                                   :through => :active_connections,
                                   :via     => :access_point

    has n, :probes

    belongs_to :mac, :required => false
    before :save do
      self.mac = Mac.first_or_create(mac: bssid)
    end

    def disconnect!
      active_connections.map(&:disconnect!)
    end

    def full_state
      {
        last_seen_at: last_seen_at,

        bssid: bssid,
        vendor: mac.vendor,
        probes: probes.map(&:essid),

        current_access_point: current_access_points.map(&:bssid).uniq,
        access_points: access_points.map(&:bssid).uniq
      }
    end
  end
end
