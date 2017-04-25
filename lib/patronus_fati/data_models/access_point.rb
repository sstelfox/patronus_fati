module PatronusFati
  module DataModels
    class AccessPoint
      include CommonState

      attr_accessor :client_macs, :local_attributes, :ssids

      LOCAL_ATTRIBUTE_KEYS = [ :bssid, :channel, :type ].freeze

      def self.current_expiration_threshold
        Time.now.to_i - AP_EXPIRATION
      end

      def active_ssids
        ssids.select { |_, v| v.active? }.values
      end

      def add_client(mac)
        client_macs << mac unless client_macs.include?(mac)
      end

      def announce_changes
        return unless dirty? && valid?

        if active?
          status = new? ? :new : :changed

          PatronusFati.event_handler.event(
            :access_point,
            status,
            full_state,
            diagnostic_data
          )
        else
          PatronusFati.event_handler.event(
            :access_point, :offline, {
              'bssid' => local_attributes[:bssid],
              'uptime' => presence.visible_time
            },
            diagnostic_data
          )

          # We need to reset the first seen so we get fresh duration
          # information
          presence.first_seen = nil

          client_macs.each do |mac|
            DataModels::Client[mac].remove_access_point(local_attributes[:bssid])
            DataModels::Connection["#{local_attributes[:bssid]}^#{mac}"].link_lost = true
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

      def diagnostic_data
        super.merge(ssids: ssids.map { |k, s| [k, s.diagnostic_data] })
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
        super
        self.local_attributes = { bssid: bssid }
        self.client_macs = []
        self.ssids = {}
      end

      def mark_synced
        super
        ssids.each { |_, v| v.mark_synced }
      end

      def remove_client(mac)
        client_macs.delete(mac)
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

      def valid?
        !([:bssid, :channel, :type].map { |k| local_attributes[k].nil? }.any?) &&
          local_attributes[:channel] != 0
      end

      def vendor
        return unless local_attributes[:bssid]
        result = Louis.lookup(local_attributes[:bssid])
        result['long_vendor'] || result['short_vendor']
      end
    end
  end
end
