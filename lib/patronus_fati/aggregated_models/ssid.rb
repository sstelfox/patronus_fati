module PatronusFati
  module AggregatedModels
    class Ssid < AggregatedModelBase
      reportable_attr :cloaked, :cryptset, :mac, :ssid, :type

      id_key do |i|
        '%s:%s' % [i[:mac], i[:ssid]]
      end
    end
  end
end
