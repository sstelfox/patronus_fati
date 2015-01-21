module PatronusFati::MessageProcessor::Client
  include PatronusFati::MessageProcessor
  extend PatronusFati::InstanceHelper

  def self.process(obj)
    PatronusFati::AggregatedModels::Client.update_or_create(obj.attributes)
    PatronusFati::AggregatedModels::Client.instances.each { |_, i| instance_report(i) }

    nil
  end
end
