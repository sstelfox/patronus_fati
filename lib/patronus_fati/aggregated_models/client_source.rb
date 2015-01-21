module PatronusFati
  module AggregatedModels
    class ClientSource < AggregatedModelBase
      def self.find(attrs)
        key = ('%s:%s' % [attrs[:mac], attrs[:uuid]])
        instances[attrs[key]]
      end

      attr_accessor :mac, :uuid

      def key
        '%s:%s' % [mac, uuid]
      end

      def update(attrs)
        self.mac = attrs[:mac] || mac
        self.uuid = attrs[:uuid] || uuid
      end
    end
  end
end
