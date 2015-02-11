module PatronusFati::DataObservers
  class ClientObserver
    include DataMapper::Observer

    observe PatronusFati::DataModels::Client

    before :save do
      break unless self.valid?
      if self.new?
        puts ('New Client: %s' % self.full_state.inspect)
      else
        dirty = self.dirty_attributes.map { |a| a.first.name }.map(&:to_s)
        dirty.delete('last_seen_at')
        next if dirty.empty?

        changes = dirty.map { |attr| '%s => [Was: \'%s\', Now: \'%s\']' % [attr, original_attributes[PatronusFati::DataModels::Client.properties[attr]], dirty_attributes[PatronusFati::DataModels::Client.properties[attr]]] }

        puts ('Updated Client: %s' % changes.join(', '))
        puts ('Updated Client: %s' % self.full_state.inspect)
      end
    end
  end
end
