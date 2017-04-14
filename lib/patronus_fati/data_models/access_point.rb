module PatronusFati::DataModels
  class AccessPoint
    attr_accessor :bssid, :channel, :type, :client_macs, :ssids, :sync_status

    def self.current_expiration_threshold
      Time.now.to_i - PatronusFati::AP_EXPIRATION
    end

    def active?
      presence.visible_since?(current_expiration_threshold)
    end

    def full_ssids
      # TODO: Lookup all the active SSIDs associated with this AP
    end

    def presence
      # TODO: Lookup this APs presence instance
    end

    def vendor
      return unless bssid
      result = Louis.lookup(bssid)
      result['long_vendor'] || result['short_vendor']
    end

    def full_state
      {
        bssid: bssid,
        channel: channel,
        type: type,
        active: active?,
        connected_clients: client_macs,
        ssids: full_ssids.map(&:full_state),
        vendor: vendor
      }
    end
  end
end
