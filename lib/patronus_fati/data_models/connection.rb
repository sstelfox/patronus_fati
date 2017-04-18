module PatronusFati
  module DataModels
    class Connection
      include CommonState

      attr_accessor :bssid, :link_lost, :mac, :presence, :sync_status

      def self.[](key)
        bssid, mac = key.split('^')
        instances[key] ||= new(bssid, mac)
      end

      def self.current_expiration_threshold
        Time.now.to_i - CONNECTION_EXPIRATION
      end

      def self.instances
        @instances ||= {}
      end

      def announce_changes
        return unless dirty?

        state = active? ? :connect : :disconnect
        PatronusFati.event_handler.event(:connection, state, full_state)

        # We need to reset the first seen so we get fresh duration information
        presence.first_seen = nil

        unless active?
          DataModels::AccessPoint[bssid].remove_client(mac)
          DataModels::Client[mac].remove_access_point(bssid)
        end

        mark_synced
      end

      def active?
        super && !link_lost
      end

      def initialize(bssid, mac)
        self.bssid = bssid
        self.link_lost = false
        self.mac = mac
        self.presence = Presence.new
        self.sync_status = 0
      end

      def full_state
        data = { 'access_point' => bssid, 'client' => mac, 'connected' => active?}
        data['duration'] = presence.visible_time if !active? && presence.visible_time
        data
      end
    end
  end
end
