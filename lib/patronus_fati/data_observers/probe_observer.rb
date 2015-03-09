module PatronusFati::DataObservers
  class ProbeObserver
    include DataMapper::Observer

    observe PatronusFati::DataModels::Probe

    after :save do
      PatronusFati.event_handler.event(:client, :changed, self.client.full_state)
    end
  end
end
