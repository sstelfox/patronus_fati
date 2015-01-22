module PatronusFati::MessageProcessor::Source
  include PatronusFati::MessageProcessor

  def self.process(obj)
    PatronusFati::AggregatedModels::Source.update_or_create(obj.attributes)
    nil
  end
end
