module PatronusFati
  module MessageModels
    Bssidsrc = CapStruct.new(
      :bssid, :uuid, :lasttime, :numpackets, :signal_dbm, :noise_dbm,
      :minsignal_dbm, :minnoise_dbm, :maxsignal_dbm, :maxnoise_dbm, :signal_rssi,
      :noise_rssi, :minsignal_rssi, :minnoise_rssi, :maxsignal_rssi,
      :maxnoise_rssi
    )
    Bssidsrc.set_data_filter(:bssid) { |val| val.downcase }
    Bssidsrc.set_data_filter(:numpackets, :signal_dbm, :noise_dbm, :firsttime,
      :lasttime, :minsignal_dbm, :minnoise_dbm, :maxsignal_dbm, :maxnoise_dbm,
      :signal_rssi, :noise_rssi, :minsignal_rssi, :minnoise_rssi,
      :maxsignal_rssi, :maxnoise_rssi) { |val| val.to_i }
  end
end
