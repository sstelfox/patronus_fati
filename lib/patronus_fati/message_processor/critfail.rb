module PatronusFati::MessageProcessor::Critfail
  include PatronusFati::MessageProcessor

  def self.process(opts)
    puts ('Critical fail message: %s' % opts.message)
    nil
  end
end
