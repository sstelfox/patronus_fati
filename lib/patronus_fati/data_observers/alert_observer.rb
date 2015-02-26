module PatronusFati::DataObservers
  class AlertObserver
    include DataMapper::Observer

    observe PatronusFati::DataModels::Alert

    after :save do
      [src_mac, dst_mac, other_mac].uniq.map(&:update_cached_counts!)

      report_data = {
        record_type: 'alert',
        report_type: 'new',
        data: self.full_state,
        timestamp: Time.now.to_i
      }
      puts JSON.generate(report_data)
    end
  end
end
