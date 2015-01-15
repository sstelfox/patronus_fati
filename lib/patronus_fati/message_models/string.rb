module PatronusFati
  module MessageModels
    String = CapStruct.new(:bssid, :source, :dest, :string)
    String.set_data_filter(:bssid) { |val| val.downcase }
  end
end
