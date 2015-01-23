module PatronusFati::MessageProcessor::Alert
  include PatronusFati::MessageProcessor

  def self.process(opts)
    time = ('%i.%i' % [opts.sec, opts.usec]).to_f
    puts ('Detected an alert: %s' % opts.attributes.merge(time: time))
    nil
  end
end
