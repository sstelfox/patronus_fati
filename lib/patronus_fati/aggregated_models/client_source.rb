module PatronusFati
  module AggregatedModels
    class ClientSource < AggregatedModelBase
      reportable_attr :mac, :uuid

      key do |i|
        '%s:%s' % [i[:mac], i[:uuid]]
      end
    end
  end
end
