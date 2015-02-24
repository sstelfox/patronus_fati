module PatronusFati::DataModels
  class Connection
    include DataMapper::Resource

    default_scope(:default).update(:order => :connected_at.desc)

    property :id,               Serial

    property :connected_at,     Integer, :default => Proc.new { Time.now.to_i }
    property :last_seen_at,     Integer, :default => Proc.new { Time.now.to_i }
    property :disconnected_at,  Integer, :default => Proc.new { Time.now.to_i }
    property :duration,         Integer

    belongs_to :access_point
    belongs_to :client

    def self.connected
      all(:disconnected_at => nil)
    end

    def self.disconnected
      all(:disconnected_at.not => nil)
    end

    def self.expired
      all(:last_seen_at.lt => (Time.now.to_i - PatronusFati::CONNECTION_EXPIRATION))
    end

    def self.unexpired
      all(:last_seen_at.gte => (Time.now.to_i - PatronusFati::CONNECTION_EXPIRATION))
    end

    def connected?
      disconnected_at.nil?
    end

    def disconnect!
      update(disconnected_at: Time.now.to_i, duration: duration) if connected?
    end

    def duration
      duration || (Time.now.to_i - connected_at)
    end

    def full_state
      {
        access_point: access_point.bssid,
        client: client.bssid,
        connected_at: connected_at
      }
    end

    def seen!(time = Time.now.to_i)
      update(:last_seen_at => time)
    end
  end
end
