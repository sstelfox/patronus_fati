module PatronusFati::MessageProcessor::Bssid
  include PatronusFati::MessageProcessor
  extend PatronusFati::InstanceHelper

  def self.process(obj)
    PatronusFati::AggregatedModels::Bssid.update_or_create(obj.attributes)
    PatronusFati::AggregatedModels::Bssid.instances.each { |_, i| instance_report(i) }

    nil
  end
end
