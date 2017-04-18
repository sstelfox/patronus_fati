module PatronusFati
  module DataModels
    class Ssid
      attr_accessor :local_attributes, :presence, :sync_status

      LOCAL_ATTRIBUTE_KEYS = [
        :beacon_info, :beacon_rate, :cloaked, :crypt_set, :essid, :max_rate
      ].freeze

      def self.current_expiration_threshold
        Time.now.to_i - SSID_EXPIRATION
      end

      def active?
        presence.visible_since?(self.class.current_expiration_threshold)
      end

      def data_dirty?
        sync_flag?(:dirtyAttributes) || sync_flag?(:dirtyChildren)
      end

      def dirty?
        new? || data_dirty? || status_dirty?
      end

      def initialize(essid)
        self.local_attributes = { essid: essid }
        self.presence = PatronusFati::Presence.new
        self.sync_status = 0
      end

      def mark_synced
        flag = active? ? :syncedOnline : :syncedOffline
        self.sync_status = SYNC_FLAGS[:flag]
      end

      def new?
        sync_status == SYNC_FLAGS[:unsynced]
      end

      def set_sync_flag(flag)
        sync_flags |= SYNC_FLAGS[flag]
      end

      def status_dirty?
        sync_flag?(:syncedOnline) && !active? ||
          sync_flag?(:syncedOffline) && active?
      end

      def sync_flag?(flag)
        (sync_status & SYNC_FLAGS[flag]) > 0
      end

      def update(attrs)
        attrs.each do |k, v|
          next unless LOCAL_ATTRIBUTE_KEYS.include?(k)
          next if local_attributes[k] == v

          set_sync_flag(:dirtyAttributes)
          local_attributes[k] = v
        end
      end
    end
  end
end
