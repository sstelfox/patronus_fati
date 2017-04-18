module PatronusFati
  module DataModels
    class Connection
      include CommonState

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

      def initialize(bssid, mac)
        self.bssid = bssid
        self.link_lost = false
        self.mac = mac
        self.presence = Presence.new
        self.sync_status = 0
      end
    end
  end
end
