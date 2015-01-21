module PatronusFati
  module MessageProcessor
    module Bssidsrc
      include MessageProcessor
      extend PatronusFati::InstanceHelper

      def self.process(obj)
        PatronusFati::AggregatedModels::BssidSource.update_or_create(obj.attributes)
        PatronusFati::AggregatedModels::BssidSource.instances.each { |_, i| instance_report(i) }

        nil
      end
    end
  end
end
