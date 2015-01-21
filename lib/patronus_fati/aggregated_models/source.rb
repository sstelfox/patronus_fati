module PatronusFati
  module AggregatedModels
    class Source < AggregatedModelBase
      key :uuid

      reportable_attr :interface, :type, :uuid
    end
  end
end
