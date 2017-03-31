module PatronusFati::MessageProcessor::Terminate
  include PatronusFati::MessageProcessor

  def self.process(obj)
    PatronusFati.logger.info('Kismet announced it\'s intention to gracefully terminate')
    nil
  end
end
