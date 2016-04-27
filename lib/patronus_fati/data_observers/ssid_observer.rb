module PatronusFati::DataObservers
  class SsidObserver
    include DataMapper::Observer

    observe PatronusFati::DataModels::Ssid

    before :save do
      next unless self.valid?

      interesting_attrs = dirty_attributes.select { |s| s.name != :last_seen_at }
      next if interesting_attrs.empty?

      @old_ssids = self.access_point.ssids.active.map(&:full_state)
        .sort_by { |s| s[:essid] }
    end

    after :save do
      # This will only be set when interesting changes have happened
      next unless @old_ssids

      new_ssids = self.access_point.ssids.active.map(&:full_state)
        .sort_by { |s| s[:essid] }

      change_list = {
        ssids: [
          @old_ssids,
          new_ssids
        ]
      }

      PatronusFati.event_handler.event(
        :access_point,
        :changed,
        self.access_point.full_state,
        change_list
      )

      @old_ssids = nil
    end
  end
end
