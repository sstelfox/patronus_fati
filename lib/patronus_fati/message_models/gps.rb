module PatronusFati
  module MessageModels
    Gps = CapStruct.new(
      :lat, :lon, :alt, :spd, :heading, :fix, :satinfo, :hdop, :vdop,
      :connected
    )
  end
end
