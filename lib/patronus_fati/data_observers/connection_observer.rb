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
      end
    end

    after :save do
      next unless @change_type

      report_data = {
        record_type: 'connection',
        report_type: @change_type,
        data: self.full_state
      }
      puts JSON.generate(report_data)

      @change_type = nil
    end
  end
end
