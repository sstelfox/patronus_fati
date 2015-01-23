module PatronusFati::MessageProcessor::Ssid
  include PatronusFati::MessageProcessor

  def self.process(obj)
    ssid_info = ssid_data(obj.attributes).select { |k, v| !v.nil? && [:cloaked,
      :type, :essid, :beacon_info, :beacon_rate, :crypt_set].include?(k) }

    if obj[:type] == 'beacon'
      # TODO: There is a BAD relatively common edge case here. Sometimes kismet
      # straight up doesn't report the existance of a BSSID but will still send
      # it's SSID information... This means we don't have channel or mode the
      # AP is operating in and I have to hard code 'fake' it. This is BAD DATA
      # and I need to figure out what to do... Perhaps the best solution is to
      # discard the data... Or maybe I need to cache the BSSID locally on the
      # SSID in the event that a BSSID is ever reported and just tie it after
      # the fact...
      #access_point = PatronusFati::DataModels::AccessPoint.first_or_create({bssid: obj[:bssid]}, ap_data(obj.attributes))

      #Fuck it I'm discarding it...
      #access_point = PatronusFati::DataModels::AccessPoint.first(bssid: obj[:bssid])
      #return unless access_point

      #ssid = access_point.ssids.first_or_create({essid: ssid_info[:essid]}, ssid_info)
      #ssid.update(ssid_info)
    else
      # Todo: I need to come back and deal with these...
      #puts ('Unknown SSID type (%s): %s' % [obj[:type], obj.inspect])
    end

    nil
  end

  protected

  # See TODO up above for why I'm hardcoding the type and channel
  def self.ap_data(attrs)
    {
      bssid: attrs[:mac],
      type: 'infrastructure',
      channel: 1
    }
  end

  def self.ssid_data(attrs)
    {
      beacon_info: attrs[:beaconinfo],
      beacon_rate: attrs[:beaconrate],
      cloaked:  attrs[:cloaked],
      crypt_set: attrs[:cryptset],
      essid: attrs[:ssid],
      max_rate: attrs[:maxrate]
    }
  end
end
