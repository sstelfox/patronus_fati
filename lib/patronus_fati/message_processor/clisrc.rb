module PatronusFati
  module MessageProcessor
    module Clisrc
      include MessageProcessor

      def self.process(obj)
        PatronusFati::AggregatedModels::ClientSource.update_or_create(obj)
        nil
      end
    end
  end
end
