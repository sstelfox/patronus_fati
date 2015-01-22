module PatronusFati::MessageProcessor::Client
  include PatronusFati::MessageProcessor

  def self.process(obj)
    PatronusFati::AggregatedModels::Client.update_or_create(obj.attributes)
    nil
  end
end
