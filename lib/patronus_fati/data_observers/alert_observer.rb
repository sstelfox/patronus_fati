module PatronusFati::DataObservers
  class AlertObserver
    include DataMapper::Observer

    observe PatronusFati::DataModels::Alert

    after :save do
      puts ('New Alert: %s' % full_state.inspect)
    end
  end
end
