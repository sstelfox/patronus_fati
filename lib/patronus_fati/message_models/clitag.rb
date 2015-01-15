module PatronusFati
  module MessageModels
    Clitag = CapStruct.new(:bssid, :mac, :tag, :value)
    Clitag.set_data_filter(:bssid, :mac) { |val| val.downcase }
  end
end
