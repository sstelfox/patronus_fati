module PatronusFati
  module AggregatedModels
    class Source < AggregatedModelBase
      def self.key; :uuid; end

      attr_accessor :interface, :type, :uuid
      alias :key :uuid

      def initialize(attrs)
        self.uuid = attrs[:uuid]
        self.interface = attrs[:interface]
        self.type = attrs[:type]

        save
      end
    end
  end
end
