module PatronusFati::DataObservers
  class SsidObserver
    include DataMapper::Observer

    observe PatronusFati::DataModels::Ssid

    before :save do
      next unless self.valid?
      if self.new?
        puts ('New SSID: %s' % self.full_state.inspect)
      else
        dirty = self.dirty_attributes.map { |a| a.first.name }.map(&:to_s)
        dirty.delete('last_seen_at')
        next if dirty.empty?

        changes = dirty.map { |attr| '%s => [Was: \'%s\', Now: \'%s\']' % [attr, original_attributes[PatronusFati::DataModels::Ssid.properties[attr]], dirty_attributes[PatronusFati::DataModels::Ssid.properties[attr]]] }

        puts ('Updated SSID: %s' % changes.join(', '))
        puts ('Updated SSID: %s' % self.current_access_points.first.full_state.inspect)
      end
    end
  end
end
