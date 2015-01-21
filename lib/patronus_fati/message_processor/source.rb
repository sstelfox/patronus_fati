module PatronusFati
  module MessageProcessor
    module Source
      include MessageProcessor
      extend InstanceHelper

      def self.process(obj)
        PatronusFati::AggregatedModels::Source.update_or_create(obj.attributes)
        PatronusFati::AggregatedModels::Source.instances.each { |_, i| instance_report(i) }

        nil
      end
    end
  end
end
