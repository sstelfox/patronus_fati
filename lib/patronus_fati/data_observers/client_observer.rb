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

      report_data = {
        record_type: 'client',
        report_type: @change_type,
        data: self.full_state
      }
      report_data[:changes] = @change_list if @change_list

      puts JSON.generate(report_data)

      @change_type = nil
      @change_list = nil
    end
  end
end
