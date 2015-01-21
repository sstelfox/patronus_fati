module PatronusFati
  module AggregatedModels
    class BssidSource < AggregatedModelBase
      key do |i|
        '%s:%s' % [i[:bssid], i[:uuid]]
      end

      reportable_attr :bssid, :uuid
    end
  end
end
