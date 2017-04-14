module PatronusFati::DataModels
  class Client
    attr_accessor :mac, :channel, :max_seen_rate, :ap_bssids, :probes,
      :sync_status

    def self.current_expiration_threshold
      Time.now.to_i - PatronusFati::CLIENT_EXPIRATION
    end

    def presence
      # TODO: Lookup this APs presence instance
    end

    def vendor
      return unless mac
      result = Louis.lookup(mac)
      result['long_vendor'] || result['short_vendor']
    end

    def full_state
      {
        mac: mac,
        channel: channel,
        max_seen_rate: max_seen_rate,
        active: presence.visible_since?(current_expiration_threshold),
        connected_access_points: ap_bssids,
        probes: probes,
        vendor: vendor
      }
    end
  end
end
