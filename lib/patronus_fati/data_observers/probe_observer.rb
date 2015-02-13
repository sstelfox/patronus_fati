module PatronusFati::DataObservers
  class ProbeObserver
    include DataMapper::Observer

    observe PatronusFati::DataModels::Probe

    before :save do
      break unless self.valid?
      puts ('New Probe detected: %s' % self.attributes.inspect)
    end
  end
end
