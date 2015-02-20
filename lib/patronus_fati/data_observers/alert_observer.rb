module PatronusFati::DataObservers
  class AlertObserver
    include DataMapper::Observer

    observe PatronusFati::DataModels::Alert

    after :save do
      puts JSON.generate(full_state)
    end
  end
end
