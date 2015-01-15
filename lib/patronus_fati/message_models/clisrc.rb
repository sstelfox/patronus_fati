module PatronusFati
  module MessageModels
    Clisrc = CapStruct.new(
      :bssid, :mac, :uuid, :lasttime, :numpackets, :signal_dbm, :noise_dbm,
      :minsignal_dbm, :minnoise_dbm, :maxsignal_dbm, :maxnoise_dbm,
      :signal_rssi, :noise_rssi, :minsignal_rssi, :minnoise_rssi,
      :maxsignal_rssi, :maxnoise_rssi
    )

    Clisrc.set_data_filter(:bssid, :mac) { |val| val.downcase }
    Clisrc.set_data_filter(:lasttime, :numpackets, :signal_dbm, :noise_dbm,
                           :minsignal_dbm, :minnoise_dbm, :maxsignal_dbm,
                           :maxnoise_dbm, :signal_rssi, :noise_rssi,
                           :minsignal_rssi, :minnoise_rssi, :maxsignal_rssi,
                           :maxnoise_rssi) { |val| val.to_i }
  end
end
