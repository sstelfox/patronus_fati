module PatronusFati
  module MessageModels
    Bssid = CapStruct.new(
      :bssid, :type, :llcpackets, :datapackets, :cryptpackets, :manuf, :channel,
      :firsttime, :lasttime, :atype, :rangeip, :netmaskip, :gatewayip, :gpsfixed,
      :minlat, :minlon, :minalt, :minspd, :maxlat, :maxlon, :maxalt, :maxspd,
      :signal_dbm, :noise_dbm, :minsignal_dbm, :minnoise_dbm, :maxsignal_dbm,
      :maxnoise_dbm, :signal_rssi, :noise_rssi, :minsignal_rssi, :minnoise_rssi,
      :maxsignal_rssi, :maxnoise_rssi, :bestlat, :bestlon, :bestalt, :agglat,
      :agglon, :aggalt, :aggpoints, :datasize, :turbocellnid, :turbocellmode,
      :turbocellsat, :carrierset, :maxseenrate, :encodingset, :decrypted,
      :dupeivpackets, :bsstimestamp, :cdpdevice, :cdpport, :fragments, :retries,
      :newpackets, :freqmhz, :datacryptset
    )
    Bssid.set_data_filter(:bssid) { |val| val.downcase }
    Bssid.set_data_filter(:llcpackets, :datapackets, :cryptpackets,
                          :firsttime, :lasttime, :atype, :gpsfixed, :minlat,
                          :minlon, :minalt, :minspd, :maxlat, :maxlon, :maxalt,
                          :maxspd, :signal_dbm, :noise_dbm, :minsignal_dbm,
                          :minnoise_dbm, :maxsignal_dbm, :maxnoise_dbm,
                          :signal_rssi, :noise_rssi, :minsignal_rssi,
                          :minnoise_rssi, :maxsignal_rssi, :maxnoise_rssi,
                          :bestlat, :bestlon, :bestalt, :agglat, :agglon,
                          :aggalt, :aggpoints, :datasize, :turbocellnid,
                          :turbocellmode, :turbocellsat, :carrierset, :channel,
                          :maxseenrate, :encodingset, :decrypted, :dupeivpackets,
                          :bsstimestamp, :fragments, :retries, :newpackets) { |val| val.to_i }

    # Attempt to map the returned BSSID type to one we know about it and
    # convert it to a string. In the event we don't know it will leave this as
    # an integer field.
    #
    # @param [String] bssid_type The string is actually an integer value in
    #   numeric form (this is how it's received from the network).
    Bssid.set_data_filter(:type) { |val| BSSID_TYPE_MAP[val.to_i] || val.to_i }
    Bssid.set_data_filter(:rangeip, :netmaskip, :gatewayip) { |val| (val == "0.0.0.0") ? nil : val }

    Bssid.set_data_filter(:freqmhz) do |val|
      raw = val.split('*').reject { |i| i.strip.empty? }.map { |v| v.split(':').map(&:to_i) }
      Hash[raw]
    end
  end
end
