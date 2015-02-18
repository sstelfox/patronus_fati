module PatronusFati::DataModels
  class Connection
    include DataMapper::Resource

    default_scope(:default).update(:order => :connected_at.desc)

    property :id, Serial

    property :connected_at,    Integer, :default => Proc.new { Time.now.to_i }
    property :last_seen_at,    Integer, :default => Proc.new { Time.now.to_i }
    property :disconnected_at, Integer

    belongs_to :client
    belongs_to :access_point

    def full_state
      {
        access_point: access_point.bssid,
        client: client.bssid,
        connected_at: connected_at,
        disconnected_at: disconnected_at
      }
    end

    def self.active
      all(:disconnected_at => nil)
    end

    def self.expired
      all(:last_seen_at.lt => (Time.now.to_i - PatronusFati::CONNECTION_EXPIRATION))
    end

    def self.unexpired
      all(:last_seen_at.gte => (Time.now.to_i - PatronusFati::CONNECTION_EXPIRATION))
    end

    def self.inactive
      all(:disconnected_at.not => nil)
    end

    def self.active_expired
      active & expired
    end

    def self.active_unexpired
      active & unexpired
    end

    def active?
      disconnected_at.nil?
    end

    def disconnect!
      update(:disconnected_at => Time.now.to_i)
    end

    def expire!
      update(:disconnected_at => last_seen_at)
    end

    def seen!
      update(:last_seen_at => Time.now.to_i)
    end
  end
end
