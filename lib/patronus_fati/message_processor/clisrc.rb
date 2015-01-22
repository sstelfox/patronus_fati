module PatronusFati::MessageProcessor::Clisrc
  include PatronusFati::MessageProcessor

  def self.process(obj)
    PatronusFati::AggregatedModels::ClientSource.update_or_create(obj.attributes)
    nil
  end
end
