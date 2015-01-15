module PatronusFati
  module MessageModels
    Btscandev = CapStruct.new(
      :bdaddr, :name, :class, :firsttime, :lasttime, :packets, :gpsfixed,
      :minlat, :minlon, :minalt, :minspd, :maxlat, :maxlon, :maxalt, :maxspd,
      :agglat, :agglon, :aggalt, :aggpoints
    )
    Btscandev.set_data_filter(:bdaddr) { |val| val.downcase }
  end
end
