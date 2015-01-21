module PatronusFati::MessageProcessor::Error
  include PatronusFati::MessageProcessor
  extend PatronusFati::InstanceHelper

  def self.process(opts)
    warn('Failed command ID %i with error: %s' % [opts.cmdid, opts.text])
  end
end
