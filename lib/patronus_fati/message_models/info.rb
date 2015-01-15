module PatronusFati
  module MessageModels
    Info = CapStruct.new(
      :networks, :packets, :crypt, :noise, :dropped, :rate, :filtered, :clients,
      :llcpackets, :datapackets, :numsources, :numerrorsources
    )
    Info.set_data_filter(:networks, :packets, :crypt, :noise, :dropped, :rate,
                         :filtered, :clients, :llcpackets, :datapackets,
                         :numsources, :numerrorsources) { |val| val.to_i }
  end
end
