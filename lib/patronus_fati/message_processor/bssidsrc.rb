module PatronusFati::MessageProcessor::Bssidsrc
  include PatronusFati::MessageProcessor

  def self.process(obj)
    PatronusFati::AggregatedModels::BssidSource.update_or_create(obj.attributes)
    nil
  end
end
