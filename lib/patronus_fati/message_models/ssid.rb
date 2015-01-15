module PatronusFati
  module MessageModels
    Ssid = CapStruct.new(
      :mac, :checksum, :type, :ssid, :beaconinfo, :cryptset, :cloaked,
      :firsttime, :lasttime, :maxrate, :beaconrate
    )
    Ssid.set_data_filter(:mac) { |val| val.downcase }
    Ssid.set_data_filter(:checksum, :firsttime, :lasttime, :maxrate,
                         :beaconrate) { |val| val.to_i }
    Ssid.set_data_filter(:cloaked) { |val| val.to_i == 1 }
    Ssid.set_data_filter(:cryptset) do |val|
      val = val.to_i
      next [SSID_CRYPT_MAP[0]] if val == 0
      SSID_CRYPT_MAP.select { |k, _| (k & val) != 0 }.map { |_, v| v }
    end

    # Attempt to map the returned SSID type to one we know about it and convert
    # it to a string. In the event we don't know it will leave this as an
    # integer field.
    #
    # @param [String] ssid_type The string is actually an integer value in
    #   numeric form (this is how it's received from the network).
    Ssid.set_data_filter(:type) { |val| SSID_TYPE_MAP[val.to_i] || val.to_i }
  end
end
