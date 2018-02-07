module PatronusFati::MessageProcessor::Ssid
  include PatronusFati::MessageProcessor

  def self.process(obj)
    # Ignore the initial flood of cached data and any objects that would have
    # already expired
    return unless PatronusFati.past_initial_flood? &&
      obj[:lasttime] >= PatronusFati::DataModels::Ssid.current_expiration_threshold

    if %w(beacon probe_response).include?(obj[:type])
      ssid_info = ssid_data(obj.attributes)

      access_point = PatronusFati::DataModels::AccessPoint[obj[:mac]]
      access_point.track_ssid(ssid_info)
      access_point.presence.mark_visible
      access_point.announce_changes
    elsif obj[:type] == 'probe_request' && !obj[:type][:ssid].empty?
      client = PatronusFati::DataModels::Client[obj[:mac]]
      client.presence.mark_visible
      client.track_probe(obj[:ssid])
      client.announce_changes
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
