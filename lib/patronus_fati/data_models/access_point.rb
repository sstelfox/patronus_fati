module PatronusFati::DataModels
  class AccessPoint
    attr_accessor :client_macs, :local_attributes, :presence, :ssids,
      :sync_status

    # This is the list of keys that represent attributes about this particular
    # AP. This does not include internal tracking state or information about
    # relations with other objects.
    LOCAL_ATTRIBUTE_KEYS = [ :bssid, :channel, :type ]

    # Various states of synchronization an individual model can be in. The
    # various sync states should remain exclusive to each other (no more than
    # one should be set). Dirtiness is an indicator of what we need to sync.
    SYNC_FLAGS = {
      unsynced: 0,
      syncedOnline: 1,
      syncedOffline: (1 << 1),
      dirtyAttributes: (1 << 2),
      dirtyChildren: (1 << 3),
    }.freeze

    def self.instances
      @instances ||= {}
    end

    def self.[](bssid)
      instances[bssid] ||= new(bssid)
    end

    def self.current_expiration_threshold
      Time.now.to_i - PatronusFati::AP_EXPIRATION
    end

    def initialize(bssid)
      self.local_attributes = { bssid: bssid }
      self.client_macs = []
      self.presence = PatronusFati::Presence.new
      self.ssids = []
      self.sync_status = 0
    end

    def active?
      presence.visible_since?(current_expiration_threshold)
    end

    def full_ssids
      # TODO: Lookup all the active SSIDs associated with this AP
    end

    def full_state
      # TODO: Add the following back in once SSIDs are tracked...
      # ssids: full_ssids.map(&:full_state),
      {
        bssid: local_attributes[:bssid],
        channel: local_attributes[:channel],
        type: local_attributes[:type],
        active: active?,
        connected_clients: local_attributes[:client_macs],
        vendor: vendor
      }
    end

    def update(attrs)
      attrs.each do |k, v|
        next unless LOCAL_ATTRIBUTE_KEYS.include?(k)
        next if local_attributes[k] == v

        self.sync_status |= SYNC_FLAGS[:dirtyAttributes]
        local_attributes[k] = v
      end
    end

    def vendor
      return unless bssid
      result = Louis.lookup(bssid)
      result['long_vendor'] || result['short_vendor']
    end
  end
end
