module PatronusFati::DataModels
  SSID_EXPIRATION = 300

  class Ssid
    include DataMapper::Resource

    property :id, Serial

    property :beacon_info, String
    property :beacon_rate, Integer
    property :cloaked,     Boolean, default: false
    property :essid,       String,  length: 64

    property :crypt_set,   Integer

    has n, :broadcasts,         :constraint => :destroy
    has n, :current_broadcasts, :model      => 'Broadcast',
                                :constraint => :destroy,
                                :child_key  => :broadcast_id,
                                :last_seen_at.gte => lambda { Time.at(Time.now.to_i - SSID_EXPIRATION) }

    has n, :access_points,         :through => :broadcasts
    has n, :current_access_points, :model   => 'AccessPoint',
                                   :through => :current_broadcasts,
                                   :via     => :access_point

    def seen!
      current_broadcasts.map(&:seen!)
    end

    # This will quietly ignore any invalid encryption types, this may still
    # result in a validation error as at least one flag needs to be set (the
    # result should never be 0).
    #
    # TODO: I need to create a custom datatype for this...
    def crypt_set=(enc_types)
      valid_values = enc_types & PatronusFati::SSID_CRYPT_MAP.values
      flag = PatronusFati::SSID_CRYPT_MAP.map { |k, v| valid_values.include?(v) ? k : 0 }.inject(&:+)
      super(flag)
    end
  end
end
