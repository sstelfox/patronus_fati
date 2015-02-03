module PatronusFati::DataModels
  class Ssid
    include DataMapper::Resource

    property :id,          Serial

    property :beacon_info, String
    property :cloaked,     Boolean, default: false
    property :essid,       String,  length: 255
    property :beacon_rate, Integer

    property :crypt_set,   Flag[*PatronusFati::SSID_CRYPT_MAP.values]

    property :last_seen_at, Time, { :default => Proc.new { Time.now } }
    timestamps :created_at

    belongs_to :access_point
  end
end
