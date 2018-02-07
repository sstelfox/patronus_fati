module PatronusFati::MessageProcessor::Bssid
  include PatronusFati::MessageProcessor

  def self.ap_data(attrs)
    {
      bssid: attrs[:bssid],
      type: attrs[:type],
      channel: attrs[:channel]
    }.reject { |_, v| v.nil? }
  end

  def self.process(obj)
    # Ignore the initial flood of cached data and any objects that would have
    # already expired
    return unless PatronusFati.past_initial_flood? &&
      obj.lasttime >= PatronusFati::DataModels::AccessPoint.current_expiration_threshold

    # Some messages from kismet come in corrupted with partial MACs. We care
    # not for them, just drop the bad data.
    return unless obj.bssid.match(/^([0-9a-f]{2}[:-]){5}[0-9a-f]{2}$/)

    # Ignore probe requests as their BSSID information is useless (the ESSID
    # isn't present and it's coming from a client).
    return unless %w(infrastructure adhoc).include?(obj.type.to_s)

    ap_info = ap_data(obj.attributes)

    access_point = PatronusFati::DataModels::AccessPoint[obj.bssid]
    access_point.update(ap_info)
    access_point.last_dbm = obj.signal_dbm if obj.signal_dbm
    access_point.presence.mark_visible
    access_point.announce_changes

    nil
  end
end
