module PatronusFati
  module MessageModels
    Alert = CapStruct.new(
      :sec, :usec, :header, :bssid, :source, :dest, :other, :channel, :text
    )

    Alert.set_data_filter(:bssid, :source, :dest, :other) { |val| val.downcase }
    Alert.set_data_filter(:sec, :usec, :channel) { |val| val.to_i }
  end
end
