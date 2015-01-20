module PatronusFati::MessageProcessor::Alert
  include PatronusFati::MessageProcessor

  def self.process(opts)
    time = ('%i.%i' % [opts.sec, opts.usec]).to_f
    PatronusFati::AggregatedModels::Alert.new(opts.attributes.merge(time: time))
    nil
  end
end
