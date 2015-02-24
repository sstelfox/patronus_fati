module PatronusFati::DataModels
  class Ssid
    include DataMapper::Resource

    property :id,           Serial

    property :beacon_rate,  Integer
    property :beacon_info,  String
    property :cloaked,      Boolean,  :default => false
    property :essid,        String,   :length  => 64
    property :last_seen_at, Integer,  :default => Proc.new { Time.now.to_i }
    property :max_rate,     Integer

    property :crypt_set,    CryptFlags

    belongs_to :access_point

    def self.active
      all(:last_seen_at.gte => (Time.now.to_i - PatronusFati::SSID_EXPIRATION))
    end

    def self.inactive
      all(:last_seen_at.lt => (Time.now.to_i - PatronusFati::SSID_EXPIRATION))
    end

    def full_state
      {
        beacon_info: beacon_info,
        beacon_rate: beacon_rate,
        cloaked: cloaked,
        crypt_set: crypt_set,
        essid: essid,
        max_rate: max_rate
      }
    end
  end
end
