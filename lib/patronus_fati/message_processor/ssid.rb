module PatronusFati::MessageProcessor::Ssid
  include PatronusFati::MessageProcessor
  extend PatronusFati::InstanceHelper

  def self.process(obj)
    PatronusFati::AggregatedModels::Ssid.update_or_create(obj.attributes)
    PatronusFati::AggregatedModels::Ssid.instances.each { |_, i| instance_report(i) }

    nil
  end
end
