module PatronusFati
  module DataModels
    class Connection
      attr_accessor :bssid, :mac, :presence, :sync_status

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
        presence.visible_since?(current_expiration_threshold)
      end

      def initialize(bssid, mac)
        self.bssid = bssid
        self.mac = mac
        self.presence = Presence.new
        self.sync_status = 0
      end
    end
  end
end
