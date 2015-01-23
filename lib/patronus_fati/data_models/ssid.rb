module PatronusFati::DataModels
  class Ssid
    include DataMapper::Resource

    property :id,          Serial

    property :beacon_info, String
    property :cloaked,     Boolean, default: false
    property :essid,       String,  length: 255
    property :max_rate,    Integer
    property :beacon_rate, Integer

    property :crypt_set,   Flag[*PatronusFati::SSID_CRYPT_MAP.values]

    belongs_to :access_point

    timestamps :at
  end
end
