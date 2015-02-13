module PatronusFati::DataObservers
  class ConnectionObserver
    include DataMapper::Observer

    observe PatronusFati::DataModels::Connection

    before :save do
      next unless self.valid?

      @change_type = self.new? ? :new : :changed

      if @change_type == :changed
        dirty = self.dirty_attributes.map { |a| a.first.name }.map(&:to_s)

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

      #if @change_type == :new
      #  ap = self.access_point.current_ssids.first
      #  essid = ap.nil? ? '' : " with SSID '#{ap.essid}'"

      #  puts ('Client %s connected to AP %s%s' % [
      #    self.client.bssid, self.access_point.bssid, essid])
      #else
      #  next if self.active? || !@change_list.keys.include?(:disconnected_at)

      #  ap = self.access_point.current_ssids.first
      #  essid = ap.nil? ? '' : " with SSID '#{ap.essid}'"

      #  puts ('Client %s disconnected from AP %s%s' % [
      #    self.client.bssid, self.access_point.bssid, essid])
      #end
    end
  end
end
