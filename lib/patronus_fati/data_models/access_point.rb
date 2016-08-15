module PatronusFati::DataModels
  class AccessPoint
    include DataMapper::Resource

    include PatronusFati::DataModels::AutoVendorLookup
    include PatronusFati::DataModels::ExpirationAttributes
    include PatronusFati::DataModels::ReportedAttributes

    property  :id,                Serial

    property  :bssid,             String, :length       => 17,
                                          :required     => true,
                                          :unique_index => true

    property  :channel,           Integer
    property  :max_seen_rate,     Integer
    property  :type,              String, :required => true

    has n, :clients,        :through    => :connections
    has n, :connections,    :constraint => :destroy,
                            :child_key  => :access_point_id
    has n, :ssids,          :constraint => :destroy

    vendor_attribute :bssid

    def self.current_expiration_threshold
      Time.now.to_i - PatronusFati::AP_EXPIRATION
    end

    def connected_clients
      connections.active.clients
    end

    def current_ssids
      ssids.active
    end

    def disconnect_clients!
      connections.connected.map(&:disconnect!)
    end

    def full_state
      blacklisted_keys = %w(id last_seen_at reported_online).map(&:to_sym)
      attributes
        .reject { |k, v| blacklisted_keys.include?(k) || v.nil? }
        .merge(
          active: active?,
          connected_clients: connected_clients.map(&:bssid),
          vendor: vendor,
          ssids: current_ssids.ordered_limit(32).map(&:full_state)
        )
    end
  end
end
