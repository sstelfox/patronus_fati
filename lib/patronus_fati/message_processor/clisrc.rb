module PatronusFati
  module MessageProcessor
    module Clisrc
      include MessageProcessor
      extend PatronusFati::InstanceHelper

      def self.process(obj)
        PatronusFati::AggregatedModels::ClientSource.update_or_create(obj.attributes)
        PatronusFati::AggregatedModels::ClientSource.instances.each { |_, i| instance_report(i) }

        nil
      end
    end
  end
end
