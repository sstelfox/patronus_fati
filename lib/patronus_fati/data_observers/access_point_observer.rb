module PatronusFati::DataObservers
  class AccessPointObserver
    include DataMapper::Observer

    observe PatronusFati::DataModels::AccessPoint

    before :save do
      next unless self.valid?

      # We're about to report this, make sure the attribute gets saved
      old_ro_val = reported_online
      self.reported_online = true

      @change_type = self.new? ? :new : :changed

      if @change_type == :changed
        dirty = self.dirty_attributes.map { |a| a.first.name }.map(&:to_s)
        dirty.select! { |k, _| full_state.keys.include?(k) }

        # If there weren't any meaningful changes, don't print out anything
        # after we save. Be aware that we may need to mark the AP as online
        # again though if we've seen it and previously reported it as offline.
        if dirty.empty? && !(olr_ro_val == false && active?)
          @change_type = nil
          self.reported_online = old_ro_val
          next
        end

        changes = dirty.map do |attr|
          clean = original_attributes[PatronusFati::DataModels::AccessPoint.properties[attr]]
          dirty = dirty_attributes[PatronusFati::DataModels::AccessPoint.properties[attr]]

          [attr, [clean, dirty]]
        end

        @change_list = Hash[changes]
      end
    end

    after :save do
      next unless @change_type

      mac.update_cached_counts!

      report_data = {
        record_type: 'access_point',
        report_type: @change_type,
        data: self.full_state,
        timestamp: Time.now.to_i
      }
      report_data[:changes] = @change_list if @change_list

      puts JSON.generate(report_data)

      @change_type = nil
      @change_list = nil
    end
  end
end
