module PatronusFati::DataModels
  class Client
    include DataMapper::Resource

    include PatronusFati::DataModels::AutoVendorLookup
    include PatronusFati::DataModels::ExpirationAttributes
    include PatronusFati::DataModels::ReportedAttributes

    property  :id,              Serial
    property  :bssid,           String,   :length => 17, :unique_index => true
    property  :channel,         Integer
    property  :max_seen_rate,   Integer

    has n, :connections,    :constraint => :destroy
    has n, :access_points,  :through    => :connections

    has n, :probes,             :constraint => :destroy

    vendor_attribute :bssid

    def self.current_expiration_threshold
      Time.now.to_i - PatronusFati::CLIENT_EXPIRATION
    end

    def connected_access_points
      connections.active.access_points
    end

    def disconnect!
      connections.connected.map(&:disconnect!)
    end

    def full_state
      blacklisted_keys = %w(id last_seen_at reported_online).map(&:to_sym)
      base_attrs = attributes.reject { |k, v| blacklisted_keys.include?(k) || v.nil? }
      base_attrs.merge(
        active: active?,
        connected_access_points: connected_access_points.map(&:bssid),
        probes: probes.map(&:essid),
        vendor: vendor
      )
    end
  end
end
