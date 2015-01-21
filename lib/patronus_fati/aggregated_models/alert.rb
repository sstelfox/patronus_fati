module PatronusFati
  module AggregatedModels
    class Alert < AggregatedModelBase
      id_key do |i|
        '%s%s%s%s%0.6f' % [i[:bssid], i[:dest], i[:other], i[:source], i[:time]]
      end

      reportable_attr :bssid, :channel, :dest, :other, :source, :text, :time
    end
  end
end
