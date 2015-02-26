module PatronusFati::DataObservers
  class ConnectionObserver
    include DataMapper::Observer

    observe PatronusFati::DataModels::Connection

    before :save do
      next unless self.valid?
      @change_type = self.new? ? :new : :changed

      if @change_type == :changed
        dirty = self.dirty_attributes.map { |a| a.first.name }.map(&:to_s)

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

      client.mac.update_cached_counts!
      access_point.mac.update_cached_counts!

      if @change_type == :new
        if disconnected_at.nil?
          report_data = {
            record_type: 'connection',
            report_type: 'connect',
            data: self.full_state,
            timestamp: Time.now.to_i
          }
          puts JSON.generate(report_data)
        else
          # Weird situation, new record that is already disconnected...
          warn('Connection (%i) created that is already disconnected' % id)
        end
      else
        if @change_list.keys.include?('disconnected_at') && @change_list['disconnected_at'][0] == nil && !disconnected_at.nil?
          report_data = {
            record_type: 'connection',
            report_type: 'disconnect',
            data: self.full_state.merge(duration: duration),
            timestamp: Time.now.to_i
          }
          puts JSON.generate(report_data)
        else
          warn('Connection (%i) updated in a weird way: %s' % [id, @change_list.inspect])
        end
      end

      @change_type = nil
      @change_list = nil
    end
  end
end
