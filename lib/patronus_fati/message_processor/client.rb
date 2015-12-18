module PatronusFati::MessageProcessor::Client
  include PatronusFati::MessageProcessor

  def self.process(obj)
    # We don't care about objects that would have expired already...
    return if obj[:lasttime] < PatronusFati::DataModels::Client.current_expiration_threshold

    client_info = client_data(obj.attributes)
    client = PatronusFati::DataModels::Client.first_or_create({bssid: obj[:mac]}, client_info)
    client.update(client_info)

    # Don't deal in associations that are outside of our connection expiration
    # time...
    return if obj[:lasttime] < PatronusFati::DataModels::Connection.current_expiration_threshold

    # Handle the associations
    unless obj[:bssid].nil? || obj[:bssid].empty? || obj[:bssid] == obj[:mac]
      return unless (ap = PatronusFati::DataModels::AccessPoint.first(bssid: obj[:bssid]))
      ap.seen!

      if (conn = PatronusFati::DataModels::Connection.connected.first(client: client, access_point: ap))
        conn.seen!
      else
        average = obj[:datasize] / obj[:datapackets]
        return unless (average >= 156 && obj[:datapackets] > 10) || (average >= 110 && obj[:datapackets] > 50)

        PatronusFati::DataModels::Connection.connected.create(client: client, access_point: ap)
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
