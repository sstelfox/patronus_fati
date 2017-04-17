module PatronusFati
  module DataModels
    class Connection
      attr_accessor :bssid, :link_lost, :mac, :presence, :sync_status

      def self.[](key)
        bssid, mac = key.split(':')
        instances[key] ||= new(bssid, mac)
      end

      def self.current_expiration_threshold
        Time.now.to_i - CONNECTION_EXPIRATION
      end

      def self.instances
        @instances ||= {}
      end

      def active?
        presence.visible_since?(self.class.current_expiration_threshold) && !link_lost
      end

      def dirty?
        return true if sync_status == SYNC_FLAGS[:unsynced] ||
                       (sync_flag?(:syncedOnline) && !active?) ||
                       (sync_flag?(:syncedOffline) && active?)
        false
      end

      def initialize(bssid, mac)
        self.bssid = bssid
        self.link_lost = false
        self.mac = mac
        self.presence = Presence.new
        self.sync_status = 0
      end

      def set_sync_flag(flag)
        sync_flags |= SYNC_FLAGS[flag]
      end

      def sync_flag?(flag)
        (sync_status & SYNC_FLAGS[flag]) > 0
      end
    end
  end
end
