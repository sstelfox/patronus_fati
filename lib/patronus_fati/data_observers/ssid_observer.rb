module PatronusFati::DataObservers
  class SsidObserver
    include DataMapper::Observer

    observe PatronusFati::DataModels::Ssid

    before :save do
      next unless self.valid?

      @change_type = self.new? ? :new : :changed
      @change_list = {
        ssids: [
          [],
          [full_state]
        ]
      }

      if @change_type == :changed
        dirty = self.dirty_attributes.map { |a| a.first.name }.map(&:to_s)
        dirty.delete('last_seen_at')

        # If there weren't any meaningful changes, don't print out anything
        # after we save.
        if dirty.empty?
          @change_list = nil
          @change_type = nil
          next
        end

        tmp_obj = Hash[original_attributes.map { |k,v| [k.name, v] }]
        @change_list[:ssids][0] = PatronusFati::DataModels::Ssid.new(tmp_obj).full_state
      end
    end

    after :save do
      next unless @change_type

      report_data = {
        record_type: 'access_point',
        report_type: @change_type,
        changes: @change_list,
        data: self.access_point.full_state
      }
      puts JSON.generate(report_data)

      @change_type = nil
      @change_list = nil
    end
  end
end
