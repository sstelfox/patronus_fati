module PatronusFati::DataModels
  class Client
    include DataMapper::Resource

    default_scope(:default).update(:order => :last_seen_at.desc)

    property  :id,              Serial
    property  :bssid,           String,   :length => 17, :unique => true
    property  :last_seen_at,    DateTime, :default => Proc.new { DateTime.now }
    property, :reported_status, String

    has n, :connections,    :constraint => :destroy
    has n, :access_points,  :through    => :connections

    has n, :probes

    belongs_to :mac, :required => false
    before :save do
      self.mac = Mac.first_or_create(mac: bssid)
    end

    def self.active
      all(:last_seen_at.gte => Time.at(Time.now.to_i - PatronusFati::CLIENT_EXPIRATION))
    end

    def self.inactive
      all(:last_seen_at.lt => Time.at(Time.now.to_i - PatronusFati::CLIENT_EXPIRATION))
    end

    def active_connections
      connections.active
    end

    def connected_access_points
      active_connections.access_points
    end

    def disconnect!
      active_connections.map(&:disconnect!)
    end

    def unreported
      all(:reported_status => nil)
    end

    def reported_active
      all(:reported_status => 'active')
    end

    def reported_expired
      all(:reported_status => 'expired')
    end

    def full_state
      {
        last_seen_at: last_seen_at,

        bssid: bssid,
        vendor: mac.vendor,
        status: status,

        probes: probes.map(&:essid),

        connected_access_point: connected_access_points.map(&:bssid).uniq,
        access_points: access_points.map(&:bssid).uniq
      }
    end
  end
end
