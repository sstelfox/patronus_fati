module PatronusFati
  module MessageModels
    Gps = CapStruct.new(:lat, :lon, :alt, :spd, :heading, :fix, :satinfo, :hdop, :vdop, :connected)
    Gps.set_data_filter(:lat, :lon, :alt, :spd, :heading, :fix, :hdop, :vdop) { |val| val.to_i }
  end
end
