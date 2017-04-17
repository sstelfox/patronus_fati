module PatronusFati::MessageProcessor::Ssid
  include PatronusFati::MessageProcessor

  def self.process(obj)
    # Ignore the initial flood of cached data and any objects that would have
    # already expired
    return unless PatronusFati.past_initial_flood? &&
      obj[:lasttime] >= PatronusFati::DataModels::Ssid.current_expiration_threshold

    if %w(beacon probe_response).include?(obj[:type])
      access_point = PatronusFati::DataModels::AccessPoint[obj[:mac]]
      access_point.presence.mark_visible

      # TODO: Track SSID
      ssid_info = ssid_data(obj.attributes)
      ssid = PatronusFati::DataModels::Ssid.first_or_create({access_point: access_point, essid: ssid_info[:essid]}, ssid_info)
      ssid.update(ssid_info)
    elsif obj[:type] == 'probe_request'
      client = PatronusFati::DataModels::Client[obj[:mac]]
      client.presence.mark_visisble
      client.track_probe(obj[:ssid])
    end

    nil
  end

  protected

  def self.ssid_data(attrs)
    crypt_set = attrs[:cryptset].map(&:to_s)
    crypt_set << 'WPS' if %w(WPS_CONFIGURED WPS_LOCKED).include?(attrs[:wps])

    {
      beacon_info: attrs[:beaconinfo],
      beacon_rate: attrs[:beaconrate],
      cloaked:     attrs[:cloaked],
      crypt_set:   crypt_set,
      essid:       attrs[:ssid],
      max_rate:    attrs[:maxrate],
    }.reject { |_, v| v.nil? }
  end
end
