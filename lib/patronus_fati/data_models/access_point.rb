module PatronusFati
  module DataModels
    class AccessPoint
      include CommonState

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

      def active_ssids
        ssids.select { |_, v| v.active? }.values
      end

      def add_client(mac)
        unless client_macs.include?(mac)
          client_macs << mac
          set_sync_flag(:dirtyChildren)
        end
      end

      def announce_changes
        return unless dirty?

        if active?
          status = new? ? :new : :changed

          PatronusFati.event_handler.event(
            :access_point,
            status,
            full_state
          )
        else
          PatronusFati.event_handler.event(
            :access_point, :offline, {
              'bssid' => local_attributes[:bssid],
              'uptime' => presence.visible_time
            }
          )

          client_macs.each do |mac|
            DataModels::Client[mac].remove_access_point(bssid)
            DataModels::Connection["#{local_attributes[:bssid]}:#{mac}"].link_lost = true
          end
        end

        mark_synced
      end

      def cleanup_ssids
        return if ssids.select { |_, v| v.presence.dead? }.empty?

        # When an AP is offline we don't care about it's SSIDs
        # expiring
        set_sync_flag(:dirtyChildren) if active? && !status_dirty?
        ssids.reject { |_, v| v.presence.dead? }
      end

      def full_state
        local_attributes.merge({
          active: active?,
          connected_clients: client_macs,
          ssids: active_ssids.map(&:local_attributes),
          vendor: vendor
        })
      end

      def initialize(bssid)
        self.local_attributes = { bssid: bssid }
        self.client_macs = []
        self.presence = Presence.new
        self.ssids = {}
        self.sync_status = 0
      end

      def mark_synced
        flag = active? ? :syncedOnline : :syncedOffline
        self.sync_status = SYNC_FLAGS[flag]
        ssids.each { |_, v| v.mark_synced }
      end

      def remove_client(mac)
        set_sync_flag(:dirtyChildren) if client_macs.delete(mac)
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
        return unless local_attributes[:bssid]
        result = Louis.lookup(local_attributes[:bssid])
        result['long_vendor'] || result['short_vendor']
      end
    end
  end
end
