module PatronusFati
  module MessageModels
    Common = CapStruct.new(
      :phytype, :macaddr, :firsttime, :lasttime, :packets, :llcpackets,
      :errorpackets, :datapackets, :cryptpackets, :datasize, :newpackets,
      :channel, :frequency, :freqmhz, :gpsfixed, :minlat, :minlon, :minalt,
      :minspd, :maxlat, :maxlon, :maxalt, :maxspd, :signaldbm, :noisedbm,
      :minsignaldbm, :minnoisedbm, :signalrssi, :noiserssi, :minsignalrssi,
      :minnoiserssi, :maxsignalrssi, :maxnoiserssi, :bestlat, :bestlon,
      :bestalt, :agglat, :agglon, :aggalt, :aggpoints
    )
    Common.set_data_filter(:macaddr) { |val| val.downcase }
    Common.set_data_filter(:firsttime, :lasttime) { |val| val.to_i }
  end
end
