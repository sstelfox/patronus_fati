module PatronusFati
  module DataModels
    module CommonState
      def active?
        presence.visible_since?(self.class.current_expiration_threshold)
      end

      def data_dirty?
        sync_flag?(:dirtyAttributes) || sync_flag?(:dirtyChildren)
      end

      def dirty?
        new? || data_dirty? || status_dirty?
      end

      def new?
        sync_status & (SYNC_FLAGS[:syncedOnline] | SYNC_FLAGS[:syncedOffline]) > 0
      end

      def mark_synced
        flag = active? ? :syncedOnline : :syncedOffline
        self.sync_status = SYNC_FLAGS[flag]
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
