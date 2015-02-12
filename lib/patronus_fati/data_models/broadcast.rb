module PatronusFati::DataModels
  # Number of seconds before we consider an access point no longer advertising an
  # SSID.
  SSID_EXPIRATION = 300

  class Broadcast
    include DataMapper::Resource

    default_scope(:default).update(:order => :last_seen_at.desc)

    property :id, Serial

    property :first_seen_at,  Time, :default => Proc.new { Time.now }
    property :last_seen_at,   Time, :default => Proc.new { Time.now }

    belongs_to :access_point
    belongs_to :ssid

    def self.active
      all(:last_seen_at.gte => Time.at(Time.now.to_i - SSID_EXPIRATION))
    end

    def self.inactive
      all(:last_seen_at.lt => Time.at(Time.now.to_i - SSID_EXPIRATION))
    end

    def seen!
      update(:last_seen_at => Time.now)
    end
  end
end
