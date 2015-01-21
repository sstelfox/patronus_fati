module PatronusFati
  module MessageProcessor
    module Bssidsrc
      include MessageProcessor

      def self.process(obj)
        PatronusFati::AggregatedModels::BssidSource.update_or_create(obj.attributes)
        nil
      end
    end
  end
end
