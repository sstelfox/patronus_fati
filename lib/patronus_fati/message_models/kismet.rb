module PatronusFati
  module MessageModels
    Kismet = CapStruct.new(
      :version, :starttime, :servername, :dumpfiles, :uid
    )
    Bssid.set_data_filter(:starttime) { |val| val.to_i }
  end
end
