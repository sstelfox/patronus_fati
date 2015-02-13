module PatronusFati::MessageProcessor::Bssid
  include PatronusFati::MessageProcessor

  def self.process(obj)
    # Ignore probe requests as their BSSID information is useless (the ESSID
    # isn't present and it's coming from a client).
    if %w(infrastructure adhoc).include?(obj.type.to_s)
      useful_data = obj.attributes.select { |k, v| !v.nil? && [:bssid, :channel, :type].include?(k) }
      useful_data.merge!(last_seen_at: DateTime.now)

      access_point = PatronusFati::DataModels::AccessPoint.first_or_create({bssid: obj.bssid}, useful_data)
      access_point.update(useful_data)
    end

    nil
  end
end
