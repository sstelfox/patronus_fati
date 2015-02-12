module PatronusFati::MessageProcessor::Bssid
  include PatronusFati::MessageProcessor

  def self.process(obj)
    # Two hours is outside of any of our expiration windows, we're probably
    # connecting to a server that has been up for a while.
    return if obj.lasttime < (Time.now.to_i - 7200)

    # Ignore probe requests as their BSSID information is useless (the ESSID
    # isn't present and it's coming from a client).
    if %w(infrastructure adhoc).include?(obj.type.to_s)
      useful_data = obj.attributes.select { |k, v| !v.nil? && [:bssid, :channel, :type].include?(k) }
      useful_data.merge!(last_seen_at: Time.now)

      access_point = PatronusFati::DataModels::AccessPoint.first_or_create({bssid: obj.bssid}, useful_data)
      access_point.update(useful_data)
    end

    nil
  end
end
