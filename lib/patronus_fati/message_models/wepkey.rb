module PatronusFati
  module MessageModels
    Wepkey = CapStruct.new(:origin, :bssid, :key, :encrypted, :failed)
    Wepkey.set_data_filter(:bssid) { |val| val.downcase }
  end
end
