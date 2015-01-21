module PatronusFati
  module AggregatedModels
    class ClientSource < AggregatedModelBase
      id_key do |i|
        '%s:%s' % [i[:mac], i[:uuid]]
      end

      reportable_attr :mac, :uuid
    end
  end
end
