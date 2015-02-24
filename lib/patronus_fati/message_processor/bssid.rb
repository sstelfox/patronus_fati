module PatronusFati::MessageProcessor::Bssid
  include PatronusFati::MessageProcessor

  def self.process(obj)
    # We don't care about objects that would have expired already...
    return if obj[:lasttime] < (Time.now.to_i - PatronusFati::AP_EXPIRATION)

    # Ignore probe requests as their BSSID information is useless (the ESSID
    # isn't present and it's coming from a client).
    return unless %w(infrastructure adhoc).include?(obj.type.to_s)

    ap_info = ap_data(obj.attributes)
    access_point = PatronusFati::DataModels::AccessPoint.first_or_create({bssid: obj.bssid}, ap_info)
    access_point.update(ap_info)
    access_point.update_frequencies(obj.freqmhz)

    nil
  end

  protected

  def self.ap_data(attrs)
    {
      bssid: attrs[:bssid],
      type: attrs[:type],
      channel: attrs[:channel],

      crypt_packets: attrs[:cryptpackets],
      data_packets: attrs[:datapackets],
      data_size: attrs[:datasize],

      fragments: attrs[:fragments],
      retries: attrs[:retries],

      signal_dbm: attrs[:signal_dbm],

      max_seen_rate: attrs[:maxseenrate],
      duplicate_iv_pkts: attrs[:dupeivpackets],

      range_ip: attrs[:rangeip],
      netmask: attrs[:netmaskip],
      gateway_ip: attrs[:gatewayip],

      last_seen_at: attrs[:lasttime],
      reported_status: 'active'
    }.reject { |_, v| v.nil? }
  end
end
