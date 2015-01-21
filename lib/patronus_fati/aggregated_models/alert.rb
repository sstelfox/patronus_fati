module PatronusFati
  module AggregatedModels
    class Alert < AggregatedModelBase
      key do |i|
        Digest::SHA256.hexdigest('%s%i%s%s%s%0.6f' % [i[:bssid], i[:channel], i[:dest], i[:other], i[:source], i[:time]])
      end

      reportable_attr :bssid, :channel, :dest, :other, :source, :text, :time
    end
  end
end
