module PatronusFati
  module MessageModels
    Nettag = CapStruct.new(:bssid, :tag, :value)
    Nettag.set_data_filter(:bssid) { |val| val.downcase }
  end
end
