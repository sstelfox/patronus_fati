module PatronusFati::DataObservers
  class AlertObserver
    include DataMapper::Observer

    observe PatronusFati::DataModels::Alert

    after :save do
      PatronusFati.event_handler.event(:alert, :new, self.full_state)
    end
  end
end
