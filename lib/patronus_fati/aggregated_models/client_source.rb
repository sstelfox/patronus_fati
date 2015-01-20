module PatronusFati
  module AggregatedModels
    class ClientSource < AggregatedModelBase
      def self.find_or_create(attrs)
        key = ('%s:%s' % [attrs[:mac], attrs[:uuid]])
        instances[attrs[key]] || new(attrs)
      end

      attr_accessor :mac, :uuid

      def initialize(attrs)
        self.mac = attrs[:mac]
        self.uuid = attrs[:uuid]

        save
      end

      def key
        '%s:%s' % [mac, uuid]
      end
    end
  end
end
