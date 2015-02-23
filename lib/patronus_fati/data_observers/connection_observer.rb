module PatronusFati::DataObservers
  class ConnectionObserver
    include DataMapper::Observer

    observe PatronusFati::DataModels::Connection

    before :destroy do
      report_data = {
        record_type: 'connection',
        report_type: 'disconnect',
        data: self.full_state.merge(duration: duration),
        timestamp: Time.now.to_i
      }
      puts JSON.generate(report_data)
    end

    before :save do
      next unless self.valid?
      next unless self.new? # We should never see this get updated...

      report_data = {
        record_type: 'connection',
        report_type: 'connect',
        data: self.full_state
      }
      puts JSON.generate(report_data)
    end
  end
end
