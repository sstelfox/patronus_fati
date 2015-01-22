module PatronusFati
  module AggregatedModels
    class Bssid < AggregatedModelBase
      expiration_time 300
      id_key :bssid
      reportable_attr :bssid, :channel, :type
    end
  end
end
