module PatronusFati
  module AggregatedModels
    class Ssid < AggregatedModelBase
      id_key do |i|
        '%s:%s' % [i[:mac], i[:ssid], i[:type], i[:cloaked]]
      end

      reportable_attr :cloaked, :cryptset, :mac, :ssid, :type
    end
  end
end
