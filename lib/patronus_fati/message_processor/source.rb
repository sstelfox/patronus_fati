module PatronusFati::MessageProcessor::Source
  include PatronusFati::MessageProcessor

  def self.process(obj)
    PatronusFati.current_channel = obj.channel
    nil
  end
end
