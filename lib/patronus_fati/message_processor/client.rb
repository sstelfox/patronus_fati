module PatronusFati::MessageProcessor::Client
  include PatronusFati::MessageProcessor

  def self.process(obj)
    # We don't care about objects that would have expired already...
    return if obj[:lasttime] < (Time.now.to_i - PatronusFati::CLIENT_EXPIRATION)

    client = PatronusFati::DataModels::Client.first_or_create(bssid: obj[:mac])
    client.seen!(obj[:lasttime])

    # Don't deal in associations that are outside of our connection expiration
    # time...
    return if obj[:lasttime] <= (Time.now.to_i - PatronusFati::CONNECTION_EXPIRATION)

    # Handle the associations
    if obj[:bssid].nil? || obj[:bssid].empty? || obj[:bssid] == obj[:mac]
      # This seems to be a problem...
      #client.disconnect!("Connected to self or blank field #{obj[:bssid]}")
    else
      return unless (ap = PatronusFati::DataModels::AccessPoint.first(bssid: obj[:bssid]))

      conn = PatronusFati::DataModels::Connection.first_or_create(
        {client: client, access_point: ap},
        {connected_at: obj[:lasttime], last_seen_at: obj[:lasttime]}
      )
      conn.seen!(last_seen_at: obj[:lasttime])
    end

    nil
  end
end
