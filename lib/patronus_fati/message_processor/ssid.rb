module PatronusFati::MessageProcessor::Ssid
  include PatronusFati::MessageProcessor

  def self.process(obj)
    # We don't care about objects that would have expired already...
    return if obj[:lasttime] < (Time.now.to_i - PatronusFati::SSID_EXPIRATION)

    ssid_info = ssid_data(obj.attributes)

    if %w(beacon probe_response).include?(obj[:type])
      access_point = PatronusFati::DataModels::AccessPoint.first(bssid: obj[:mac])
      return unless access_point # Only happens with a corrupt message

      ssid = PatronusFati::DataModels::Ssid.first_or_create({access_point: access_point, essid: ssid_info[:essid]}, ssid_info)
      ssid.update(ssid_info)
    elsif obj[:type] == 'probe_request'
      client = PatronusFati::DataModels::Client.first(bssid: obj[:mac])
      return if client.nil? || obj[:ssid].nil? || obj[:ssid].empty?
      client.probes.first_or_create(essid: obj[:ssid])
    else
      # The only thing left is the 'file' type which no one seems to understand
      #puts ('Unknown SSID type (%s): %s' % [obj[:type], obj.inspect])
    end

    nil
  end

  protected

  def self.ssid_data(attrs)
    {
      beacon_info: attrs[:beaconinfo],
      beacon_rate: attrs[:beaconrate],
      cloaked:  attrs[:cloaked],
      crypt_set: attrs[:cryptset].map(&:to_s),
      essid: attrs[:ssid],
      last_seen_at: attrs[:lasttime],
      max_rate: attrs[:maxrate]
    }.reject { |_, v| v.nil? }
  end
end
