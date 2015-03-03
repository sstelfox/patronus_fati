module PatronusFati::DataObservers
  class ProbeObserver
    include DataMapper::Observer

    observe PatronusFati::DataModels::Probe

    after :save do
      report_data = {
        record_type: 'client',
        report_type: 'changed',
        data: self.client.full_state,
        timestamp: Time.now.to_i
      }

      puts JSON.generate(report_data)
    end
  end
end
