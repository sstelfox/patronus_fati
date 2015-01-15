module PatronusFati
  module MessageModels
    Remove = CapStruct.new(:bssid)
    Remove.set_data_filter(:bssid) { |val| val.downcase }
  end
end
