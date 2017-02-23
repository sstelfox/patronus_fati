module PatronusFati::MessageProcessor::Error
  include PatronusFati::MessageProcessor

  def self.process(opts)
    PatronusFati.logger.warn('Failed command ID %i with error: %s' % [opts.cmdid, opts.text])
  end
end
