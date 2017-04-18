module PatronusFati
  module DataModels
    class Client
      attr_accessor :access_point_bssids, :local_attributes, :presence, :probes,
        :sync_status

      LOCAL_ATTRIBUTE_KEYS = [ :mac, :channel, :max_seen_rate ].freeze

      def self.[](mac)
        instances[mac] ||= new(mac)
      end

      def self.current_expiration_threshold
        Time.now.to_i - CLIENT_EXPIRATION
      end

      def self.exists?(mac)
        instances.key?(mac)
      end

      def self.instances
        @instances ||= {}
      end

      def active?
        presence.visible_since?(self.class.current_expiration_threshold)
      end

      def add_access_point(bssid)
        unless access_point_bssids.include?(bssid)
          access_point_bssids << bssid
          set_sync_flag(:dirtyChildren)
        end
      end

      def cleanup_probes
        return if probes.select { |_, v| v.presence.dead? }.empty?

        set_sync_flag(:dirtyChildren)
        probes.reject { |_, v| v.presence.dead? }
      end

      def dirty?
        return true if sync_status == SYNC_FLAGS[:unsynced] ||
                       sync_flag?(:dirtyAttributes) ||
                       sync_flag?(:dirtyChildren) ||
                       (sync_flag?(:syncedOnline) && !active?) ||
                       (sync_flag?(:syncedOffline) && active?)
        false
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
        self.access_point_bssids = []
        self.local_attributes = { mac: mac }
        self.presence = Presence.new
        self.probes = {}
        self.sync_status = 0
      end

      def remove_access_point(bssid)
        set_sync_flag(:dirtyChildren) if access_point_bssids.delete(mac)
      end

      def set_sync_flag(flag)
        sync_flags |= SYNC_FLAGS[flag]
      end

      def sync_flag?(flag)
        (sync_status & SYNC_FLAGS[flag]) > 0
      end

      def track_probe(probe)
        return unless probe && probe.length > 0

        self.probes[probe] ||= Presence.new
        self.probes[probe].mark_visible
      end

      def update(attrs)
        attrs.each do |k, v|
          next unless LOCAL_ATTRIBUTE_KEYS.include?(k)
          next if local_attributes[k] == v

          set_sync_flag(:dirtyAttributes)
          local_attributes[k] = v
        end
      end

      def vendor
        return unless local_attributes[:mac]
        result = Louis.lookup(local_attributes[:mac])
        result['long_vendor'] || result['short_vendor']
      end
    end
  end
end
