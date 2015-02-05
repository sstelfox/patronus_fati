module PatronusFati::MessageProcessor::Client
  include PatronusFati::MessageProcessor

  def self.process(obj)
    # Two hours is outside of any of our expiration windows, we're probably
    # connecting to a server that has been up for a while.
    return if obj.lasttime < (Time.now.to_i - 7200)

    client = PatronusFati::DataModels::Client.first_or_create({bssid: obj[:mac]})
    client.update(last_seen_at: Time.now)

    # Handle the associations
    client.disconnect! if obj[:bssid].nil?
    if obj[:bssid] && obj[:bssid] != obj[:mac]
      return unless (ap = PatronusFati::DataModels::AccessPoint.first(bssid: obj[:bssid]))
      client.access_points << ap
      client.save
    end

    nil
  end
end
