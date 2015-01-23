module PatronusFati::MessageProcessor::Ssid
  include PatronusFati::MessageProcessor

  def self.process(obj)
    obj = convert_attr_names(obj.attributes)
    useful_data = obj.select { |k, v| !v.nil? && [:bssid, :cloaked, :type,
      :essid, :beacon_info, :beacon_rate, :crypt_set].include?(k) }

    if useful_data.delete(:type) == 'beacon'
      access_point = PatronusFati::DataModels::AccessPoint.first(bssid: useful_data.delete(:bssid))
      ssid = access_point.ssids.first_or_create({essid: useful_data[:essid]}, useful_data)
      ssid.update(useful_data)
    else
      # Todo: I need to come back and deal with these...
      #puts ('Unknown SSID type (%s): %s' % [useful_data[:type], useful_data.inspect])
    end

    nil
  end

  protected

  def self.convert_attr_names(attrs)
    {
      beacon_info: attrs[:beaconinfo],
      beacon_rate: attrs[:beaconrate],
      bssid: attrs[:mac],
      cloaked:  attrs[:cloaked],
      crypt_set: attrs[:cryptset],
      essid: attrs[:ssid],
      max_rate: attrs[:maxrate],
      type:  attrs[:type]
    }
  end
end
