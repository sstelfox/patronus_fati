module PatronusFati::MessageProcessor::Bssid
  include PatronusFati::MessageProcessor

  def self.process(obj)
    PatronusFati::AggregatedModels::Bssid.update_or_create(obj.attributes)
    nil
  end
end
