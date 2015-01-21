module PatronusFati::MessageProcessor::Error
  include PatronusFati::MessageProcessor

  def self.process(opts)
    warn('Failed command ID %i with error: %s' % [opts.cmdid, opts.text])
  end
end
