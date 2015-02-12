module PatronusFati::DataModels
  class Broadcast
    include DataMapper::Resource

    default_scope(:default).update(:order => :last_seen_at.desc)

    property :id, Serial

    property :first_seen_at,  Time, :default => Proc.new { Time.now }
    property :last_seen_at,   Time, :default => Proc.new { Time.now }

    belongs_to :access_point
    belongs_to :ssid

    def self.active
      all(:last_seen_at.gte => Time.at(Time.now.to_i - PatronusFati::SSID_EXPIRATION))
    end

    def self.inactive
      all(:last_seen_at.lt => Time.at(Time.now.to_i - PatronusFati::SSID_EXPIRATION))
    end

    def active?
      last_seen_at >= Time.at(Time.now.to_i - PatronusFati::SSID_EXPIRATION)
    end

    def seen!
      update(:last_seen_at => Time.now)
    end
  end
end
