module PatronusFati::DataObservers
  class SsidObserver
    include DataMapper::Observer

    observe PatronusFati::DataModels::Ssid

    before :save do
      next unless self.valid?

      # We're about to report this, make sure the attribute gets saved
      old_ro_val = reported_online
      self.reported_online = true

      @change_list = {
        ssids: [
          [],
          [full_state]
        ]
      }

      unless self.new?
        dirty = self.dirty_attributes.map { |a| a.first.name }.map(&:to_s)
        dirty.delete('last_seen_at')

        # If there weren't any meaningful changes, don't print out anything
        # after we save.
        if dirty.empty?
          @change_list = nil
          self.reported_online = old_ro_val
          next
        end

        tmp_obj = Hash[original_attributes.map { |k,v| [k.name, v] }]
        @change_list[:ssids][0] = PatronusFati::DataModels::Ssid.new(tmp_obj).full_state
      end
    end

    after :save do
      next unless @change_list

      access_point.mac.update_cached_counts!

      report_data = {
        record_type: 'access_point',
        report_type: :changed,
        changes: @change_list,
        data: self.access_point.full_state,
        timestamp: Time.now.to_i
      }
      puts JSON.generate(report_data)

      @change_list = nil
    end
  end
end
