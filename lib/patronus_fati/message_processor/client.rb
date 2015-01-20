module PatronusFati::MessageProcessor::Client
  include PatronusFati::MessageProcessor

  def self.process(obj)
    PatronusFati::AggregatedModels::Client.find_or_create(obj)
    nil
  end
end
