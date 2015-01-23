module PatronusFati::DataObservers
  class AccessPointObserver
    include DataMapper::Observer

    observe PatronusFati::DataModels::AccessPoint

    before :save do
      break unless self.valid?
      if self.new?
        #puts ('New access point detected: %s' % self.attributes.inspect)
      else
        #puts ('Access Point updated (%s): %s' % [self.dirty_attributes.map { |a| a.first.name }, a.attributes.inspect])
      end
    end
  end
end
