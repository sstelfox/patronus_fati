module PatronusFati::DataObservers
  class SsidObserver
    include DataMapper::Observer

    observe PatronusFati::DataModels::Ssid

    before :save do
      unless self.valid?
        puts ('Invalid %s' % self.attributes)
      end

      if self.new?
        #puts ('New SSID detected: %s' % self.attributes.inspect)
      else
        puts ('SSID updated (%s): %s' % [self.dirty_attributes.map { |a| a.first.name }, a.attributes.inspect])
      end
    end
  end
end
