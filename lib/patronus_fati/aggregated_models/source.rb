module PatronusFati
  module AggregatedModels
    class Source < AggregatedModelBase
      id_key :uuid

      reportable_attr :interface, :type, :uuid
    end
  end
end
