module PatronusFati::DataModels
  class Connection
    include DataMapper::Resource

    include PatronusFati::DataModels::ExpirationAttributes

    property :id,               Serial

    property :connected_at,     Integer, :default => Proc.new { Time.now.to_i }
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

    def self.current_expiration_threshold
      Time.now.to_i - PatronusFati::CONNECTION_EXPIRATION
    end

    def connected?
      disconnected_at.nil?
    end

    def disconnect!
      update(disconnected_at: Time.now.to_i, duration: duration) if connected?
    end

    def duration
      self[:duration] || (Time.now.to_i - connected_at)
    end

    def full_state
      {
        access_point: access_point.bssid,
        client: client.bssid,
        connected_at: connected_at
      }
    end
  end
end
