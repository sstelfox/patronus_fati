module PatronusFati::DataObservers
  class ProbeObserver
    include DataMapper::Observer

    observe PatronusFati::DataModels::Probe

    before :save do
      break unless self.valid?
      if self.new?
        puts ('New Probe detected: %s' % self.attributes.inspect)
      else
        dirty = self.dirty_attributes.map { |a| a.first.name }.map(&:to_s)
        dirty.delete('last_seen_at')

        unless dirty.empty?
          # We should never see this...
          puts 'THIS SHOULD NEVER HAPPEN:'
          puts ('Probe updated (%s): %s' % [dirty.join(','), self.attributes.inspect])
        end
      end
    end
  end
end
