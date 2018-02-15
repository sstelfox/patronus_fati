module PatronusFati
  module DataModels
    class AccessPoint
      include CommonState

      attr_accessor :client_macs, :last_dbm, :local_attributes, :ssids

      LOCAL_ATTRIBUTE_KEYS = [ :bssid, :channel, :type ].freeze

      def self.current_expiration_threshold
        Time.now.to_i - AP_EXPIRATION
      end

      def active_ssids
        return unless ssids
        # If there is any active SSIDs return them
        active = ssids.select { |_, v| v.active? }
        return active unless active.empty?

        # If there are no active SSIDs try and find the most recently seen SSID
        # and report that as still active. Still return an empty set if there
        # are no SSIDs.
        most_recent = ssids.sort_by { |_, v| v.presence.last_visible || 0 }.last
        most_recent ? Hash[[most_recent]] : {}
      end

      def add_client(mac)
        client_macs << mac unless client_macs.include?(mac)
      end

      def announce_changes
        return unless dirty? && valid? && worth_syncing?

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

      def broadcasting_multiple?
        return false unless ssids
        return false if active_ssids.count == 1

        presences = active_ssids.values.map(&:presence)
        # This check becomes very expensive at larger numbers, if we get too
        # high just short circuit and assume that yes there are simultaneous
        # SSIDs being transmitted. This is likely a sign of a malicious device.
        return true if presences.length >= 100

        current_presence_bits = presences.map { |p| p.current_presence.bits }
        return true if PatronusFati::BitHelper.largest_bit_overlap(current_presence_bits) >= SIMULTANEOUS_SSID_THRESHOLD

        last_presence_bits = presences.map { |p| p.last_presence.bits }
        return true if PatronusFati::BitHelper.largest_bit_overlap(last_presence_bits) >= SIMULTANEOUS_SSID_THRESHOLD

        false
      end

      def cleanup_ssids
        return if ssids.nil? || ssids.select { |_, v| v.presence.dead? }.empty?

        # When an AP is offline we don't care about announcing that it's SSIDs
        # have expired, but we do want to remove them.
        set_sync_flag(:dirtyChildren) if active?

        ssids.reject! { |_, v| v.presence.dead? }
      end

      def diagnostic_data
        dd = super
        dd.merge!(ssids: Hash[ssids.map { |k, s| [k, s.diagnostic_data] }]) if ssids
        dd[:last_dbm] = last_dbm if last_dbm
        dd
      end

      def full_state
        state = local_attributes.merge({
          active: active?,
          broadcasting_multiple: broadcasting_multiple?,
          connected_clients: client_macs,
          vendor: vendor
        })
        state[:ssids] = active_ssids.values.map(&:full_state) if ssids
        state
      end

      def initialize(bssid)
        super
        self.local_attributes = { bssid: bssid }
        self.client_macs = []
      end

      def mark_synced
        super
        ssids.each { |_, v| v.mark_synced } if ssids
      end

      def remove_client(mac)
        client_macs.delete(mac)
      end

      def track_ssid(ssid_data)
        self.ssids ||= {}

        ssid_key = ssid_data[:cloaked] ?
          Digest::SHA256.hexdigest(ssid_data[:crypt_set].join) :
          ssid_data[:essid]

        ssids[ssid_key] ||= DataModels::Ssid.new(ssid_data[:essid])

        ssid = ssids[ssid_key]
        ssid.presence.mark_visible
        ssid.update(ssid_data)

        set_sync_flag(:dirtyChildren) if ssid.dirty?
      end

      def update(attrs)
        attrs.each do |k, v|
          next unless LOCAL_ATTRIBUTE_KEYS.include?(k)
          next if v.nil? || local_attributes[k] == v

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

      # This is a safety mechanism to check whether or not an access point is
      # actually 'present'. This is intended to assist in cutting out the
      # access points that are just on the edge of being visible to our sensors.
      def worth_syncing?
        client_macs.any? || sync_flag?(:syncedOnline) ||
          (presence && presence.visible_time && presence.visible_time > INTERVAL_DURATION)
      end
    end
  end
end
