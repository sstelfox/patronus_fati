module PatronusFati
  module AggregatedModels
    class BssidSource < AggregatedModelBase
      def self.find(attrs)
        key = ('%s:%s' % [attrs[:bssid], attrs[:uuid]])
        instances[attrs[key]]
      end

      attr_accessor :bssid, :uuid

      def key
        '%s:%s' % [bssid, uuid]
      end

      def update(attrs)
        self.bssid = attrs[:bssid] || bssid
        self.uuid = attrs[:uuid] || uuid
      end
    end
  end
end
