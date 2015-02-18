module PatronusFati::MessageProcessor::Client
  include PatronusFati::MessageProcessor

  def self.process(obj)
    client = PatronusFati::DataModels::Client.first_or_create(bssid: obj[:mac])
    client.seen!(obj[:lasttime])

    # Don't deal in associations that are outside of our connection expiration
    # time...
    return if obj[:lasttime] < (Time.now.to_i - PatronusFati::CONNECTION_EXPIRATION)

    # Handle the associations
    if obj[:bssid].nil? || obj[:bssid].empty? || obj[:bssid] == obj[:mac]
      client.disconnect!
    else
      return unless (ap = PatronusFati::DataModels::AccessPoint.first(bssid: obj[:bssid]))

      conn = client.connections.active_unexpired.all(access_point: ap).first ||
        PatronusFati::DataModels::Connection.create(access_point: ap, client: client,
        connected_at: obj[:lasttime], last_seen_at: obj[:lasttime])

      conn.seen!
    end

    nil
  end
end
