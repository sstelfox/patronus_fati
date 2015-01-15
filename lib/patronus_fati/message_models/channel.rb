module PatronusFati
  module MessageModels
    Channel = CapStruct.new(
      :channel, :time_on, :packets, :packetsdelta, :usecused, :bytes,
      :bytesdelta, :networks, :maxsignal_dbm, :maxsignal_rssi, :maxnoise_dbm,
      :maxnoise_rssi, :activenetworks
    )
  end
end
