module PatronusFati::DataModels
  class Client
    include DataMapper::Resource

    default_scope(:default).update(:order => :last_seen_at.desc)

    property  :id,              Serial
    property  :bssid,           String,   :length => 17, :unique => true
    property  :last_seen_at,    Integer,  :default => Proc.new { Time.now.to_i }
    property  :reported_status, String,   :default => 'active'

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

    def self.reported_active
      all(:reported_status => 'active')
    end

    def self.reported_expired
      all(:reported_status => 'expired')
    end

    def connected_access_points
      connections.unexpired.access_points
    end

    def disconnect!
      connections.map(&:destroy)
    end

    def full_state
      {
        bssid: bssid,
        vendor: mac.vendor,

        connected_access_points: connected_access_points.map(&:bssid).uniq,
        probes: probes.map(&:essid),
      }
    end

    def seen!(time = Time.now.to_i)
      update(last_seen_at: time, reported_status: 'active')
    end
  end
end
