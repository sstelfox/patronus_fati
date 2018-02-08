module PatronusFati
  module DataModels
    class Client
      include CommonState

      attr_accessor :access_point_bssids, :last_dbm, :local_attributes, :probes

      LOCAL_ATTRIBUTE_KEYS = [ :mac, :channel ].freeze

      def self.current_expiration_threshold
        Time.now.to_i - CLIENT_EXPIRATION
      end

      def add_access_point(bssid)
        access_point_bssids << bssid unless access_point_bssids.include?(bssid)
      end

      def announce_changes
        return unless dirty? && valid? && worth_syncing?

        if active?
          status = new? ? :new : :changed
          PatronusFati.event_handler.event(:client, status, full_state, diagnostic_data)
        else
          PatronusFati.event_handler.event(
            :client, :offline, {
              'bssid' => local_attributes[:mac],
              'uptime' => presence.visible_time
            },
            diagnostic_data
          )

          # We need to reset the first seen so we get fresh duration information
          presence.first_seen = nil

          access_point_bssids.each do |bssid|
            DataModels::AccessPoint[bssid].remove_client(local_attributes[:mac])
            DataModels::Connection["#{bssid}^#{local_attributes[:mac]}"].link_lost = true
          end
        end

        mark_synced
      end

      # Probes don't have an explicit visibility window so this will only
      # remove probes that haven't been seen in the entire duration of the time
      # we track any visibility.
      def cleanup_probes
        return if probes.select { |_, pres| pres.dead? }.empty?
        set_sync_flag(:dirtyChildren)
        probes.reject! { |_, pres| pres.dead? }
      end

      def diagnostic_data
        dd = super
        dd[:last_dbm] = last_dbm if last_dbm
        dd[:visible_time] = presence.visible_time
        dd
      end

      def full_state
        {
          active: active?,
          bssid: local_attributes[:mac],
          channel: local_attributes[:channel],
          connected_access_points: access_point_bssids,
          probes: probes.keys,
          vendor: vendor
        }
      end

      def initialize(mac)
        super
        self.access_point_bssids = []
        self.local_attributes = { channel: 0, mac: mac }
        self.probes = {}
      end

      def remove_access_point(bssid)
        access_point_bssids.delete(bssid)
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

      def valid?
        !local_attributes[:mac].nil?
      end

      def vendor
        return unless local_attributes[:mac]
        result = Louis.lookup(local_attributes[:mac])
        result['long_vendor'] || result['short_vendor']
      end

      # This is a safety mechanism to check whether or not a client device is
      # actually 'present'. This is intended to cut out the one time fake
      # generated addresses from devices that generate random MAC addresses,
      # probe quickly and disappear and requires us to either see a client
      # connect to an access point, be visible for more than one interval, or
      # have already been synced.
      def worth_syncing?
        access_point_bssids.any? || sync_flag?(:syncedOnline) ||
          (presence && presence.visible_time && presence.visible_time > INTERVAL_DURATION)
      end
    end
  end
end
