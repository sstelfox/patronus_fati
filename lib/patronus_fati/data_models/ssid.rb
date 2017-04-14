module PatronusFati::DataModels
  class Ssid
    attr_accessor :bssid, :beacon_info, :beacon_rate, :cloaked, :crypt_set,
      :essid, :max_rate

    def self.current_expiration_threshold
      Time.now.to_i - PatronusFati::SSID_EXPIRATION
    end

    def active?
      presence.visible_since?(current_expiration_threshold)
    end

    def presence
      # TODO: Lookup this SSIDs presence instance
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
