module PatronusFati::DataObservers
  class BroadcastObserver
    include DataMapper::Observer

    observe PatronusFati::DataModels::Broadcast

    before :save do
      next unless self.valid?
      next unless self.new?

      puts ('AP %s is now broadcasting ESSID \'%s\'' % [self.access_point.bssid, self.ssid.essid])
    end
  end
end
