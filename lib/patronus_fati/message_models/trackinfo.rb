module PatronusFati
  module MessageModels
    Trackinfo = CapStruct.new(
      :devices, :packets, :datapackets, :cryptpackets, :errorpackets,
      :filterpackets, :packetrate
    )
  end
end
