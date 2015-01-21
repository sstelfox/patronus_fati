module PatronusFati
  module MessageProcessor
    module Source
      include MessageProcessor

      def self.process(obj)
        PatronusFati::AggregatedModels::Source.update_or_create(obj.attributes)
        nil
      end
    end
  end
end
