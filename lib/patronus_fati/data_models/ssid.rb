module PatronusFati::DataModels
  class Ssid
    include DataMapper::Resource

    property :id,           Serial

    property :beacon_rate,  Integer
    property :cloaked,      Boolean, default: false
    property :essid,        String,  length: 64

    property :crypt_set,    Integer

    has n, :broadcasts,     :constraint => :destroy
    has n, :access_points,  :through    => :broadcasts

    def active_access_points
      active_broadcasts.access_points
    end

    def active_broadcasts
      broadcasts.active
    end

    def seen!
      active_broadcasts.map(&:seen!)
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

    def full_state
      {
        beacon_rate: beacon_rate,
        cloaked: cloaked,
        essid: essid,
        crypt_set: crypt_set
      }
    end
  end
end
