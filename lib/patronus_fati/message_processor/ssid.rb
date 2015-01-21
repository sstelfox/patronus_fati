module PatronusFati::MessageProcessor::Ssid
  include PatronusFati::MessageProcessor

  def self.process(obj)
    PatronusFati::AggregatedModels::Ssid.update_or_create(obj.attributes)
    nil
  end
end
