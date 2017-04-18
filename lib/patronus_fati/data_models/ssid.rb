module PatronusFati
  module DataModels
    class Ssid
      include CommonState

      attr_accessor :local_attributes, :presence, :sync_status

      LOCAL_ATTRIBUTE_KEYS = [
        :beacon_info, :beacon_rate, :cloaked, :crypt_set, :essid, :max_rate
      ].freeze

      def self.current_expiration_threshold
        Time.now.to_i - SSID_EXPIRATION
      end

      def initialize(essid)
        self.local_attributes = { essid: essid }
        self.presence = PatronusFati::Presence.new
        self.sync_status = 0
      end

      def update(attrs)
        attrs.each do |k, v|
          next unless LOCAL_ATTRIBUTE_KEYS.include?(k)
          next if local_attributes[k] == v

          set_sync_flag(:dirtyAttributes)
          local_attributes[k] = v
        end

        if !cloaked && (essid.nil? || essid.empty?)
          PatronusFati.logger.warn('Detected empty ESSID on uncloaked AP!')
        end
      end
    end
  end
end
