module PatronusFati::MessageProcessor::Ssid
  include PatronusFati::MessageProcessor

  def self.process(obj)
    ssid_info = ssid_data(obj.attributes).select { |k, v| !v.nil? }

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
      # TODO: I think these are all dealt with, I might want to change this to
      # a warning.
      puts ('Unknown SSID type (%s): %s' % [obj[:type], obj.inspect])
    end

    nil
  end

  protected

  def self.ssid_data(attrs)
    {
      beacon_rate: attrs[:beaconrate],
      cloaked:  attrs[:cloaked],
      crypt_set: attrs[:cryptset],
      essid: attrs[:ssid],
      last_seen_at: Time.at(attrs[:lasttime])
    }
  end
end
