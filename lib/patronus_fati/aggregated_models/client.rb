module PatronusFati
  module AggregatedModels
    class Client < AggregatedModelBase
      reportable_attr :bssid, :channel, :mac, :type
    end
  end
end
