module PatronusFati
  module AggregatedModels
    class Source < AggregatedModelBase
      def self.key; :uuid; end

      attr_accessor :interface, :type, :uuid
      alias :key :uuid

      def update(attrs)
        self.uuid = attrs[:uuid] || uuid
        self.interface = attrs[:interface] || interface
        self.type = attrs[:type] || type
      end
    end
  end
end
