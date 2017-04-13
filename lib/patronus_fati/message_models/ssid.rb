module PatronusFati
  module MessageModels
    # NOTE: If you change these fields the SSID message parser needs to be
    # manually updated since these fields are very broken.
    Ssid = CapStruct.new(
      :mac, :checksum, :type, :ssid, :beaconinfo, :cryptset, :cloaked,
      :maxrate, :beaconrate, :firsttime, :lasttime, :wps, :wps_device_name,
      :wps_manuf, :wps_model_name, :wps_model_number
    )
    Ssid.set_data_filter(:mac) { |val| val.downcase }
    Ssid.set_data_filter(:checksum, :firsttime, :lasttime, :maxrate,
                         :beaconrate) { |val| val.to_i }
    Ssid.set_data_filter(:cloaked) { |val| val.to_i == 1 }
    Ssid.set_data_filter(:cryptset) do |val|
      val = val.to_i
      next [SSID_CRYPT_MAP[0]] if val == 0

      # The WEP bit is always set if the AP is encrypted. If it is the only bit
      # set then the AP is really broadcasting WEP. If it is anything else it
      # is not necessarily not running WEP but WEP will be indicated using the
      # other flags.
      val = val ^ SSID_CRYPT_MAP_INVERTED['WEP'] if val > SSID_CRYPT_MAP_INVERTED['WEP']

      SSID_CRYPT_MAP.select { |k, _| (k & val) != 0 }.map { |_, v| v }
    end
    Ssid.set_data_filter(:wps) do |val|
      next WPS_SETTING_MAP[0] unless val
      next WPS_SETTING_MAP[0] if val.ord == 0

      WPS_SETTING_MAP.select { |k, _| (k & val.ord) != 0 }.map { |_, v| v}.first
    end
    Ssid.set_data_filter(:wps_device_name) do |val|
      next if val.nil? || val.empty?
      val
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
