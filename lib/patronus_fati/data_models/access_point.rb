module PatronusFati
  module DataModels
    class AccessPoint
      attr_accessor :client_macs, :local_attributes, :presence, :ssids,
        :sync_status

      LOCAL_ATTRIBUTE_KEYS = [ :bssid, :channel, :type ].freeze

      def self.[](bssid)
        instances[bssid] ||= new(bssid)
      end

      def self.current_expiration_threshold
        Time.now.to_i - AP_EXPIRATION
      end

      def self.instances
        @instances ||= {}
      end

      def active?
        presence.visible_since?(self.class.current_expiration_threshold)
      end

      def active_ssids
        ssids.select { |_, v| v.active? }.values
      end

      def add_client(mac)
        unless client_macs.include?(mac)
          client_macs << mac
          set_sync_flag(:dirtyChildren)
        end
      end

      def cleanup_ssids
        return if ssids.select { |_, v| v.presence.dead? }.empty?

        set_sync_flag(:dirtyChildren)
        ssids.reject { |_, v| v.presence.dead? }
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
          bssid: local_attributes[:bssid],
          channel: local_attributes[:channel],
          type: local_attributes[:type],
          active: active?,
          connected_clients: local_attributes[:client_macs],
          ssids: active_ssids.map(&:local_attributes),
          vendor: vendor
        }
      end

      def initialize(bssid)
        self.local_attributes = { bssid: bssid }
        self.client_macs = []
        self.presence = Presence.new
        self.ssids = {}
        self.sync_status = 0
      end

      def remove_client(mac)
        set_sync_flag(:dirtyChildren) if client_macs.delete(mac)
      end

      def set_sync_flag(flag)
        sync_flags |= SYNC_FLAGS[flag]
      end

      def sync_flag?(flag)
        (sync_status & SYNC_FLAGS[flag]) > 0
      end

      def track_ssid(ssid_data)
        ssids[ssid_data[:essid]] ||= DataModels::Ssid.new(ssid_data[:essid])

        ssid = ssids[ssid_data[:essid]]
        ssid.presence.mark_visible
        ssid.update(ssid_data)

        set_sync_flag(:dirtyChildren) if ssid.dirty?
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
        return unless bssid
        result = Louis.lookup(bssid)
        result['long_vendor'] || result['short_vendor']
      end
    end
  end
end
