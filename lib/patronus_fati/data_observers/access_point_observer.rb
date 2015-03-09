module PatronusFati::DataObservers
  class AccessPointObserver
    include DataMapper::Observer

    observe PatronusFati::DataModels::AccessPoint

    before :save do
      next unless self.valid?

      self.reported_online = active?

      @change_type = self.new? ? :new : :changed

      if @change_type == :changed
        dirty = self.dirty_attributes.map { |a| a.first.name }.map(&:to_s)
        dirty.select! { |k, _| full_state.keys.include?(k) || k == 'reported_online' }

        # If there weren't any meaningful changes, don't print out anything
        # after we save.
        if dirty.empty?
          @change_type = nil
          next
        end

        changes = dirty.map do |attr|
          clean = original_attributes[PatronusFati::DataModels::AccessPoint.properties[attr]]
          dirty = dirty_attributes[PatronusFati::DataModels::AccessPoint.properties[attr]]

          [attr, [clean, dirty]]
        end

        @change_list = Hash[changes]
        @change_list.delete('reported_online')
      end
    end

    after :save do
      next unless @change_type

      mac.update_cached_counts!

      PatronusFati.event_handler.event(
        :access_point,
        @change_type,
        self.full_state,
        @change_list || {}
      )

      @change_type = nil
      @change_list = nil
    end
  end
end
