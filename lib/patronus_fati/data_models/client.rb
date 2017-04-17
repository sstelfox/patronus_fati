module PatronusFati::DataModels
  class Client
    attr_accessor :access_point_bssids, :local_attributes, :presence, :probes,
      :sync_status

    # This is the list of keys that represent attributes about this particular
    # Client.
    LOCAL_ATTRIBUTE_KEYS = [ :mac, :channel, :max_seen_rate ].freeze

    def self.[](mac)
      instances[mac] ||= new(mac)
    end

    def self.current_expiration_threshold
      Time.now.to_i - PatronusFati::CLIENT_EXPIRATION
    end

    def self.exists?(mac)
      instances.key?(mac)
    end

    def self.instances
      @instances ||= {}
    end

    def active?
      presence.visible_since?(current_expiration_threshold)
    end

    def full_state
      {
        mac: mac,
        channel: channel,
        max_seen_rate: max_seen_rate,
        active: presence.visible_since?(current_expiration_threshold),
        connected_access_points: access_point_bssids,
        probes: probes.keys,
        vendor: vendor
      }
    end

    def initialize(mac)
      self.access_point_bssids = {}
      self.local_attributes = { mac: mac }
      self.presence = PatronusFati::Presence.new
      self.probes = {}
      self.sync_status = 0
    end

    def track_probe(probe)
      return unless probe && probe.length > 0

      self.probes[probe] ||= PatronusFati::Presence.new
      self.probes[probe].mark_presence
    end

    def update(attrs)
      attrs.each do |k, v|
        next unless LOCAL_ATTRIBUTE_KEYS.include?(k)
        next if local_attributes[k] == v

        self.sync_status |= PatronusFati::SYNC_FLAGS[:dirtyAttributes]
        local_attributes[k] = v
      end
    end

    def vendor
      return unless mac
      result = Louis.lookup(mac)
      result['long_vendor'] || result['short_vendor']
    end
  end
end
