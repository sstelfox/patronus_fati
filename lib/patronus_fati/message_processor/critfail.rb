module PatronusFati::MessageProcessor::Critfail
  include PatronusFati::MessageProcessor

  def self.process(opts)
    PatronusFati.logger.error('Critical fail message: %s' % opts.message)
    nil
  end
end
