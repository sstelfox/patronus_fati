module PatronusFati::DataObservers
  class ClientObserver
    include DataMapper::Observer

    observe PatronusFati::DataModels::Client

    before :save do
      break unless self.valid?

      @change_type = self.new? ? :new : :changed
      if @change_type == :changed
        dirty = self.dirty_attributes.map { |a| a.first.name }.map(&:to_s)
        dirty.delete('last_seen_at')

        # If there weren't any meaningful changes, don't print out anything
        # after we save.
        if dirty.empty?
          @change_type = nil
          next
        end

        changes = dirty.map do |attr|
          clean = original_attributes[PatronusFati::DataModels::Client.properties[attr]]
          dirty = dirty_attributes[PatronusFati::DataModels::Client.properties[attr]]

          [attr, [clean, dirty]]
        end

        @change_list = Hash[changes]
      end
    end

    after :save do
      next unless @change_type

      puts ('Client (%s): %s' % [@change_type, self.full_state.inspect])
      if @change_list
        puts ('-----> (%s): %s' % [@change_list.keys.join(','), @change_list.map { |k, v| '%: (%s => %s)' % [k, v[0], v[1]] }])
      end

      @change_type = nil
      @change_list = nil
    end
  end
end
