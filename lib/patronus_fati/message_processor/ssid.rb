module PatronusFati::MessageProcessor::Ssid
  include PatronusFati::MessageProcessor

  def self.process(obj)
    # Two hours is outside of any of our expiration windows, we're probably
    # connecting to a server that has been up for a while.
    return if obj.lasttime < (Time.now.to_i - 7200)

    ssid_info = ssid_data(obj.attributes).select { |k, v| !v.nil? }

    if %w(beacon probe_response).include?(obj[:type])
      access_point = PatronusFati::DataModels::AccessPoint.first(bssid: obj[:mac])
      return unless access_point # Only happens with a corrupt message

      ssid = access_point.ssids.first_or_create({essid: ssid_info[:essid]}, ssid_info)
      ssid.update(ssid_info)
      ssid.seen!

      # Not a normal association unfortunately, we want to create a new one if
      # the old association has expired.
      unless access_point.current_ssids.include?(ssid)
        PatronusFati::DataModels::Broadcast.create(access_point: access_point, ssid: ssid)
      end
    elsif obj[:type] == 'probe_request'
      client = PatronusFati::DataModels::Client.first(bssid: obj[:mac])
      return if client.nil? || obj[:ssid].nil? || obj[:ssid].empty?
      client.probes.first_or_create(essid: obj[:ssid])
    else
      # TODO: I think these are all dealt with, I might want to change this to
      # a warning.
      puts ('Unknown SSID type (%s): %s' % [obj[:type], obj.inspect])
    end

    nil
  end

  protected

  def self.ssid_data(attrs)
    {
      beacon_rate: attrs[:beaconrate],
      cloaked:  attrs[:cloaked],
      crypt_set: attrs[:cryptset],
      essid: attrs[:ssid]
    }
  end
end
