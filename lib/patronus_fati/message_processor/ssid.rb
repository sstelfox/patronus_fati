module PatronusFati::MessageProcessor::Ssid
  include PatronusFati::MessageProcessor

  def self.process(obj)
    # Two hours is outside of any of our expiration windows, we're probably
    # connecting to a server that has been up for a while.
    return if obj.lasttime < (Time.now.to_i - 7200)

    ssid_info = ssid_data(obj.attributes).select { |k, v| !v.nil? }
    ssid_info.merge!(last_seen_at: Time.now)

    if %w(beacon probe_response).include?(obj[:type])
      access_point = PatronusFati::DataModels::AccessPoint.first(bssid: obj[:mac])
      return unless access_point # Only happens with a corrupt message

      ssid = access_point.ssids.first_or_create({essid: ssid_info[:essid]}, ssid_info)
      ssid.update(ssid_info)
    elsif obj[:type] == 'probe_request'
      client = PatronusFati::DataModels::Client.first(mac: obj[:mac])
      return if client.nil? || obj[:ssid].nil? || obj[:ssid].empty?
      client.probes.first_or_create(name: obj[:ssid])
    else
      # Todo: I need to come back and deal with these...
      puts ('Unknown SSID type (%s): %s' % [obj[:type], obj.inspect])
    end

    nil
  end

  protected

  def self.ssid_data(attrs)
    {
      beacon_info: attrs[:beaconinfo],
      beacon_rate: attrs[:beaconrate],
      cloaked:  attrs[:cloaked],
      crypt_set: attrs[:cryptset],
      essid: attrs[:ssid]
    }
  end
end
