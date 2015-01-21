module PatronusFati
  module AggregatedModels
    class Bssid < AggregatedModelBase
      key :bssid

      reportable_attr :bssid, :channel, :type
    end
  end
end
