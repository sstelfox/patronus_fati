module PatronusFati
  module AggregatedModels
    class BssidSource < AggregatedModelBase
      def self.find_or_create(attrs)
        key = ('%s:%s' % [attrs[:bssid], attrs[:uuid]])
        instances[attrs[key]] || new(attrs)
      end

      attr_accessor :bssid, :uuid

      def initialize(attrs)
        self.bssid = attrs[:bssid]
        self.uuid = attrs[:uuid]

        save
      end

      def key
        '%s:%s' % [bssid, uuid]
      end
    end
  end
end
