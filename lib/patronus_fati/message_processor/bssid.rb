module PatronusFati::MessageProcessor::Bssid
  include PatronusFati::MessageProcessor

  def self.process(obj)
    # We don't care about objects that would have expired already...
    return if obj[:lasttime] < (Time.now.to_i - PatronusFati::AP_EXPIRATION)

    # Ignore probe requests as their BSSID information is useless (the ESSID
    # isn't present and it's coming from a client).
    if %w(infrastructure adhoc).include?(obj.type.to_s)
      useful_data = obj.attributes.select { |k, v| !v.nil? && [:bssid, :channel, :type].include?(k) }
      useful_data.merge!(last_seen_at: obj[:lasttime])

      access_point = PatronusFati::DataModels::AccessPoint.first_or_create({bssid: obj.bssid}, useful_data)
      access_point.update(useful_data)

      access_point.seen!(obj[:lasttime])
    end

    nil
  end
end
