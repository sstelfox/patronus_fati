module PatronusFati::DataObservers
  class SsidObserver
    include DataMapper::Observer

    observe PatronusFati::DataModels::Ssid

    before :save do
      next unless self.valid?

      if self.new?
        puts ('New SSID detected: %s' % self.attributes.inspect)
      else
        dirty = self.dirty_attributes.map { |a| a.first.name }.map(&:to_s)
        dirty.delete('last_seen_at')

        next if dirty.empty?

        changes = dirty.map { |attr| '%s => [Was: \'%s\', Now: \'%s\']' % [attr, original_attributes[PatronusFati::DataModels::Ssid.properties[attr]], dirty_attributes[PatronusFati::DataModels::Ssid.properties[attr]]] }
        puts ('SSID updated: %s' % changes.join(', '))
      end
    end
  end
end
