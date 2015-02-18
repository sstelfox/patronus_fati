module PatronusFati::DataModels
  class Client
    include DataMapper::Resource

    default_scope(:default).update(:order => :last_seen_at.desc)

    property  :id,              Serial
    property  :bssid,           String,   :length => 17, :unique => true
    property  :last_seen_at,    Integer,  :default => Proc.new { Time.now.to_i }
    property  :reported_status, String

    has n, :connections,    :constraint => :destroy
    has n, :access_points,  :through    => :connections

    has n, :probes

    belongs_to :mac, :required => false
    before :save do
      self.mac = Mac.first_or_create(mac: bssid)
    end

    def self.active
      all(:last_seen_at.gte => (Time.now.to_i - PatronusFati::CLIENT_EXPIRATION))
    end

    def self.inactive
      all(:last_seen_at.lt => (Time.now.to_i - PatronusFati::CLIENT_EXPIRATION))
    end

    def connected_access_points
      connections.active_unexpired.access_points
    end

    def disconnect!
      connections.active.map(&:disconnect!)
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

        probes: probes.map(&:essid),

        connected_access_point: connected_access_points.map(&:bssid).uniq,
        access_points: access_points.map(&:bssid).uniq
      }
    end
  end
end
