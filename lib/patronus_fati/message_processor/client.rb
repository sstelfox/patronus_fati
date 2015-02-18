module PatronusFati::MessageProcessor::Client
  include PatronusFati::MessageProcessor

  def self.process(obj)
    client = PatronusFati::DataModels::Client.first_or_create(bssid: obj[:mac])
    client.update(last_seen_at: obj[:lasttime])

    # Don't deal in associations that are outside of our connection expiration
    # time... Just disconnect it using expirations and drop out of this
    # processing.
    if obj[:lasttime] < (Time.now.to_i - PatronusFati::CONNECTION_EXPIRATION)
      client.connections.active_unexpired.map(&:expire!)
      return
    end

    # Handle the associations
    if obj[:bssid].nil? || obj[:bssid].empty? || obj[:bssid] == obj[:mac]
      client.disconnect!
    else
      return unless (ap = PatronusFati::DataModels::AccessPoint.first(bssid: obj[:bssid]))

      if (conn = client.connections.active_unexpired.all(access_point_id: ap.id).first)
        conn.seen!
      else
        PatronusFati::DataModels::Connection.create(access_point: ap, client: client)
      end
    end

    nil
  end
end
