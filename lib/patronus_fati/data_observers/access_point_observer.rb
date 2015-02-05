module PatronusFati::DataObservers
  class AccessPointObserver
    include DataMapper::Observer

    observe PatronusFati::DataModels::AccessPoint

    before :save do
      break unless self.valid?

      if self.new?
        puts ('New AP: %s' % self.full_state.inspect)
      else
        dirty = self.dirty_attributes.map { |a| a.first.name }.map(&:to_s)
        dirty.delete('last_seen_at')

        next if dirty.empty?

        changes = dirty.map { |attr| '%s => [Was: \'%s\', Now: \'%s\']' % [attr, original_attributes[PatronusFati::DataModels::AccessPoint.properties[attr]], dirty_attributes[PatronusFati::DataModels::AccessPoint.properties[attr]]] }
        puts ('Updated AP: %s' % changes.join(', '))
      end
    end
  end
end
