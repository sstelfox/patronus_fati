module PatronusFati
  module DataModels
    module CommonState
      module KlassMethods
        def [](key)
          instances[key] ||= new(key)
        end

        def exists?(mac)
          instances.key?(mac)
        end

        def instances
          @instances ||= {}
        end
      end

      def self.included(klass)
        klass.extend(KlassMethods)
      end

      def active?
        presence.visible_since?(self.class.current_expiration_threshold)
      end

      def data_dirty?
        sync_flag?(:dirtyAttributes) || sync_flag?(:dirtyChildren)
      end

      def diagnostic_data
        {
          sync_status: sync_status,
          current_presence: presence.current_presence.bits,
          last_presence: presence.last_presence.bits
        }
      end

      def dirty?
        new? || data_dirty? || status_dirty?
      end

      def initialize(*_args)
        self.presence = Presence.new
        self.sync_status = 0
      end

      def mark_synced
        flag = active? ? :syncedOnline : :syncedOffline
        self.sync_status = SYNC_FLAGS[flag]
      end

      def new?
        !(sync_flag?(:syncedOnline) || sync_flag?(:syncedOffline))
      end

      def set_sync_flag(flag)
        self.sync_status |= SYNC_FLAGS[flag]
      end

      def status_dirty?
        sync_flag?(:syncedOnline) && !active? ||
          sync_flag?(:syncedOffline) && active?
      end

      def sync_flag?(flag)
        (sync_status & SYNC_FLAGS[flag]) > 0
      end
    end
  end
end
