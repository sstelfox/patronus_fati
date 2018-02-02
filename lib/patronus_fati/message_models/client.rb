module PatronusFati
  module MessageModels
    Client = CapStruct.new(
      :bssid, :mac, :type, :firsttime, :lasttime, :manuf, :llcpackets,
      :datapackets, :cryptpackets, :gpsfixed, :minlat, :minlon, :minalt,
      :minspd, :maxlat, :maxlon, :maxalt, :maxspd, :agglat, :agglon, :aggalt,
      :aggpoints, :signal_dbm, :noise_dbm, :minsignal_dbm, :minnoise_dbm,
      :maxsignal_dbm, :maxnoise_dbm, :signal_rssi, :noise_rssi,
      :minsignal_rssi, :minnoise_rssi, :maxsignal_rssi, :maxnoise_rssi,
      :bestlat, :bestlon, :bestalt, :atype, :ip, :gatewayip, :datasize,
      :maxseenrate, :encodingset, :carrierset, :decrypted, :channel,
      :fragments, :retries, :newpackets, :freqmhz, :cdpdevice, :cdpport,
      :dot11d, :dhcphost, :dhcpvendor, :datacryptset
    )
    Client.set_data_filter(:bssid, :mac) { |val| val.downcase }

    # Attempt to map the returned client type to one we know about it and
    # convert it to a string. In the event we don't know it will leave this as
    # an integer field.
    #
    # @param [String] client_type The string is actually an integer value in
    #   numeric form (this is how it's received from the network).
    Client.set_data_filter(:type) { |val| CLIENT_TYPE_MAP[val.to_i] || val.to_i }
    Client.set_data_filter(:firsttime, :lasttime, :llcpackets, :datapackets,
                           :cryptpackets, :minlat, :minlon, :minalt, :minspd,
                           :maxlat, :maxlon, :maxalt, :maxspd, :agglat,
                           :agglon, :aggalt, :aggpoints, :signal_dbm,
                           :noise_dbm, :minsignal_dbm, :minnoise_dbm,
                           :maxsignal_dbm, :maxnoise_dbm, :signal_rssi,
                           :noise_rssi, :minsignal_rssi, :minnoise_rssi,
                           :maxsignal_rssi, :maxnoise_rssi, :bestlat, :bestlon,
                           :bestalt, :atype, :datasize, :maxseenrate,
                           :encodingset, :carrierset, :decrypted,
                           :fragments, :retries, :newpackets) { |val| val.to_i }
    Client.set_data_filter(:channel) { |val| val.to_i == 0 ? nil : val.to_i }
    Client.set_data_filter(:gpsfixed) { |val| val.to_i == 1 }

    Client.set_data_filter(:ip, :gatewayip) { |val| (val == "0.0.0.0") ? nil : val }
    Client.set_data_filter(:dhcphost) { |val| (val || '').strip.empty? ? nil : val }

    Client.set_data_filter(:freqmhz) do |val|
      raw = val.to_s.split('*').compact.reject { |i| (i || '').strip.empty? }.map { |v| v.split(':').map(&:to_i) }
      Hash[raw]
    end
  end
end
