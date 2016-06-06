module PatronusFati::MessageProcessor::Client
  include PatronusFati::MessageProcessor

  def self.process(obj)
    # We don't care about objects that would have expired already...
    return if obj[:lasttime] < PatronusFati::DataModels::Client.current_expiration_threshold

    unless obj[:bssid].nil? || obj[:bssid].empty? || obj[:bssid] == obj[:mac]
      return unless (ap = PatronusFati::DataModels::AccessPoint.first(bssid: obj[:bssid]))
      ap.seen!
    end

    # Some messages from kismet come in corrupted with partial MACs. We care
    # not for them, just drop the bad data.
    return unless obj[:mac].match(/^([0-9a-f]{2}[:-]){5}[0-9a-f]{2}$/)

    client_info = client_data(obj.attributes)

    # These potentially represent wired assets leaking through the WiFi and
    # devices not following the 802.11 spec.
    if %w( unknown from_ds ).include?(obj[:type]) || obj[:mac].nil?
      client = PatronusFati::DataModels::Client.first({bssid: obj[:mac]})
    else
      client = PatronusFati::DataModels::Client.first_or_create({bssid: obj[:mac]}, client_info)
    end
    client.update(client_info) if client

    # Don't deal in associations that are outside of our connection expiration
    # time...
    return if obj[:lasttime] < PatronusFati::DataModels::Connection.current_expiration_threshold

    # Handle the associations
    if ap && client
      if (conn = PatronusFati::DataModels::Connection.connected.first(client: client, access_point: ap))
        conn.seen!
      else
        PatronusFati::DataModels::Connection.create(client: client, access_point: ap)
      end
    end

    nil
  end

  protected

  def self.client_data(attrs)
    {
      bssid: attrs[:mac],
      channel: attrs[:channel],
      max_seen_rate: attrs[:maxseenrate],
      last_seen_at: Time.now.to_i
    }.reject { |_, v| v.nil? }
  end
end
