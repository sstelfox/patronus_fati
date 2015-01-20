module PatronusFati
  module MessageProcessor
    module Bssidsrc
      include MessageProcessor

      def self.process(obj)
        PatronusFati::AggregatedModels::BssidSource.find_or_create(obj)
        nil
      end
    end
  end
end
