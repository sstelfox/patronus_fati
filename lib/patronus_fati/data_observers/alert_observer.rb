module PatronusFati::DataObservers
  class AlertObserver
    include DataMapper::Observer

    observe PatronusFati::DataModels::Alert

    after :save do
      [src_mac, dst_mac, other_mac].uniq.map(&:update_cached_counts!)
      PatronusFati.event_handler.event(:alert, :new, self.full_state)
    end
  end
end
