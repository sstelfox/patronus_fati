module PatronusFati::DataObservers
  class AccessPointObserver
    include DataMapper::Observer

    observe PatronusFati::DataModels::AccessPoint

    before :save do
      break unless self.valid?
      if self.new?
        puts ('New access point detected: %s' % self.attributes.inspect)
      else
        dirty = self.dirty_attributes.map { |a| a.first.name }.map(&:to_s)
        dirty.delete('last_seen_at')

        unless dirty.empty?
          puts ('Access Point updated (%s): %s' % [dirty.join(','), self.attributes.inspect])
        end
      end
    end
  end
end
