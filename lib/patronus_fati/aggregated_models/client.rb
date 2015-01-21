module PatronusFati
  module AggregatedModels
    class Client < AggregatedModelBase
      id_key :mac
      reportable_attr :bssid, :channel, :mac, :type
    end
  end
end
