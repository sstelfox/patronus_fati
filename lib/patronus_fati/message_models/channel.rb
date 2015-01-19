module PatronusFati
  module MessageModels
    Channel = CapStruct.new(
      :channel, :time_on, :packets, :packetsdelta, :usecused, :bytes,
      :bytesdelta, :networks, :maxsignal_dbm, :maxsignal_rssi, :maxnoise_dbm,
      :maxnoise_rssi, :activenetworks
    )
    Channel.set_data_filter(:channel, :time_on, :packets, :packetsdelta,
      :usecused, :bytes, :bytesdelta, :networks, :maxsignal_dbm,
      :maxsignal_dbm, :maxsignal_rssi, :maxnoise_dbm, :maxnoise_rssi,
      :activenetworks) { |val| val.to_i }
  end
end
