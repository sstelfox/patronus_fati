module PatronusFati::DataModels
  class Ssid
    include DataMapper::Resource

    include PatronusFati::DataModels::ExpirationAttributes
    include PatronusFati::DataModels::ReportedAttributes

    property :id,           Serial

    property :beacon_rate,  Integer
    property :beacon_info,  String

    property :cloaked,      Boolean,  :default => false
    property :essid,        String,   :length  => 64
    property :crypt_set,    CryptFlags
    property :max_rate,     Integer

    belongs_to :access_point

    def self.current_expiration_threshold
      Time.now.to_i - PatronusFati::SSID_EXPIRATION
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
