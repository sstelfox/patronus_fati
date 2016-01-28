module PatronusFati::MessageProcessor::Bssid
  include PatronusFati::MessageProcessor

  def self.process(obj)
    # We don't care about objects that would have expired already...
    return if obj[:lasttime] < (Time.now.to_i - PatronusFati::AP_EXPIRATION)

    # Some messages from kismet come in corrupted with partial MACs. We care
    # not for them, just drop the bad data.
    return unless obj[:mac].match(/^([0-9a-f]{2}[:-]){5}[0-9a-f]{2}$/)

    # Ignore probe requests as their BSSID information is useless (the ESSID
    # isn't present and it's coming from a client).
    return unless %w(infrastructure adhoc).include?(obj.type.to_s)

    ap_info = ap_data(obj.attributes)
    access_point = PatronusFati::DataModels::AccessPoint.first_or_create({bssid: obj.bssid}, ap_info)
    access_point.update(ap_info)

    nil
  end

  protected

  def self.ap_data(attrs)
    {
      bssid: attrs[:bssid],
      type: attrs[:type],
      channel: attrs[:channel],
      last_seen_at: Time.now.to_i
    }.reject { |_, v| v.nil? }
  end
end
