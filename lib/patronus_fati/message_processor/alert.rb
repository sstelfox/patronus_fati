module PatronusFati::MessageProcessor::Alert
  include PatronusFati::MessageProcessor
  extend PatronusFati::InstanceHelper

  def self.process(opts)
    time = ('%i.%i' % [opts.sec, opts.usec]).to_f

    PatronusFati::AggregatedModels::Alert.update_or_create(opts.attributes.merge(time: time))
    PatronusFati::AggregatedModels::Alert.instances.each { |_, i| instance_report(i) }

    nil
  end
end
