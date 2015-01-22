module PatronusFati::MessageProcessor::Protocols
  include PatronusFati::MessageProcessor

  def self.process(obj)
    obj.protocols.split(',').map { |p| "CAPABILITY #{p}" }
  end
end
