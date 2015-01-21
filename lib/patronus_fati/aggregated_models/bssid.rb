module PatronusFati
  module AggregatedModels
    class Bssid < AggregatedModelBase
      id_key :bssid

      reportable_attr :bssid, :channel, :type
    end
  end
end
