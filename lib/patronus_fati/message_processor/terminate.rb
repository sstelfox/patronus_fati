module PatronusFati::MessageProcessor::Terminate
  include PatronusFati::MessageProcessor

  def self.process(obj)
    puts 'Kismet announced it\'s intention to gracefully terminate'

    nil
  end
end
