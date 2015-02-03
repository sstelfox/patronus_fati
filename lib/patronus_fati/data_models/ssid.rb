module PatronusFati::DataModels
  class Ssid
    include DataMapper::Resource

    property :id,          Serial

    property :beacon_info, String
    property :cloaked,     Boolean, default: false
    property :essid,       String,  length: 255
    property :beacon_rate, Integer

    property :crypt_set,   Integer

    property :last_seen_at, Time, { :default => Proc.new { Time.now } }
    timestamps :created_at

    belongs_to :access_point

    # This will quietly ignore any invalid encryption types, this may still
    # result in a validation error as at least one flag needs to be set (the
    # result should never be 0).
    def crypt_set=(enc_types)
      valid_values = enc_types & PatronusFati::SSID_CRYPT_MAP.values
      flag = PatronusFati::SSID_CRYPT_MAP.map { |k, v| valid_values.include?(v) ? k : 0 }.inject(&:+)
      super(flag)
    end
  end
end
