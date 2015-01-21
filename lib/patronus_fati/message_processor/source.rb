module PatronusFati
  module MessageProcessor
    module Source
      include MessageProcessor

      def self.process(obj)
        PatronusFati::AggregatedModels::Source.update_or_create(obj)
        nil
      end
    end
  end
end
