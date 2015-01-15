module PatronusFati
  module MessageModels
    Packet = CapStruct.new(
      :type, :subtype, :timesec, :encrypted, :weak, :beaconrate, :sourcemac,
      :destmac, :bssid, :ssid, :prototype, :sourceip, :destip, :sourceport,
      :destport, :nbtype, :nbsource, :sourcename
    )
    Packet.set_data_filter(:bssid, :destmac, :sourcemac) { |val| val.downcase }
  end
end
