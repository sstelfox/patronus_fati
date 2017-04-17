module PatronusFati::MessageProcessor::Client
  include PatronusFati::MessageProcessor

  def self.client_data(attrs)
    {
      bssid:          attrs[:mac],
      channel:        attrs[:channel],
      max_seen_rate:  attrs[:maxseenrate],
    }.reject { |_, v| v.nil? }
  end

  def self.connection_threshold
    Time.now.to_i - PatronusFati::CONNECTION_EXPIRATION
  end

  def self.process(obj)
    # Ignore the initial flood of cached data and any objects that would have
    # already expired
    return unless PatronusFati.past_initial_flood? &&
      obj[:lasttime] >= PatronusFati::DataModels::Client.current_expiration_threshold

    # obj[:mac] is the client's MAC address
    # obj[:bssid] is the AP's MAC address
    unless obj[:bssid].nil? || obj[:bssid].empty? || obj[:bssid] == obj[:mac]
      access_point = PatronusFati::DataModels::AccessPoint[obj[:bssid]]
      access_point.presence.mark_visible
    end

    # Some messages from kismet come in corrupted with partial MACs. We care
    # not for them, just drop the bad data.
    return unless obj[:mac].match(/^([0-9a-f]{2}[:-]){5}[0-9a-f]{2}$/)

    # These potentially represent wired assets leaking through the WiFi and
    # devices not following the 802.11 spec. We will use them for presence
    # information if the client is already known to us and they're legitimately
    # coming from a known access point. It's possible that we haven't seen the
    # AP yet, but that will only delay the visibility of the client until they
    # actually transmit.
    return if %w(unknown from_ds).include?(obj[:type]) &&
      (!PatronusFati::DataModels::Client.exists?(obj[:mac]) || access_point.nil?)

    client_info = client_data(obj.attributes)

    client = PatronusFati::DataModels::Client[obj[:mac]]
    client.update(client_info)
    client.presence.mark_visible

    # Don't deal in associations that are outside of our connection expiration
    # time... or if we don't have an access point
    return if obj[:lasttime] < connection_threshold || access_point.nil?

    access_point.add_client(obj[:mac])
    client.add_access_point(obj[:bssid])

    # TODO: Track connection

    nil
  end
end
