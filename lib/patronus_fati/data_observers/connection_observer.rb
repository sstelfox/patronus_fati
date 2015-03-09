module PatronusFati::DataObservers
  class ConnectionObserver
    include DataMapper::Observer

    observe PatronusFati::DataModels::Connection

    before :save do
      next unless self.valid?
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
          clean = original_attributes[PatronusFati::DataModels::Connection.properties[attr]]
          dirty = dirty_attributes[PatronusFati::DataModels::Connection.properties[attr]]

          [attr, [clean, dirty]]
        end

        @change_list = Hash[changes]
      end
    end

    after :save do
      next unless @change_type

      client.mac.update_cached_counts!
      access_point.mac.update_cached_counts!

      if @change_type == :new
        if disconnected_at.nil?
          PatronusFati.event_handler.event(
            :connection,
            :connect,
            self.full_state
          )
        else
          # Weird situation, new record that is already disconnected...
          warn('Connection (%i) created that is already disconnected' % id)
        end
      else
        if @change_list.keys.include?('disconnected_at') && @change_list['disconnected_at'][0] == nil && !disconnected_at.nil?
          PatronusFati.event_handler.event(
            :connection,
            :disconnect,
            self.full_state.merge(duration: duration)
          )
        else
          warn('Connection (%i) updated in a weird way: %s' % [id, @change_list.inspect])
        end
      end

      @change_type = nil
      @change_list = nil
    end
  end
end
