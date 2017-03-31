module PatronusFati::MessageProcessor::Ssid
  include PatronusFati::MessageProcessor

  def self.process(obj)
    # Ignore the initial flood of cached data and any objects that would have
    # already expired
    return unless PatronusFati.past_initial_flood? &&
      obj[:lasttime] >= PatronusFati::DataModels::Ssid.current_expiration_threshold

    ssid_info = ssid_data(obj.attributes)

    if %w(beacon probe_response).include?(obj[:type])
      access_point = PatronusFati::DataModels::AccessPoint.first(bssid: obj[:mac])
      return unless access_point # Only happens with a corrupt message

      ssid = PatronusFati::DataModels::Ssid.first_or_create({access_point: access_point, essid: ssid_info[:essid]}, ssid_info)
      unless ssid.saved?
        puts "Created but failed to persist SSID for unknown reason. Available validation errors: #{ssid.errors.to_a.inspect}"
        raise "SSID wasn't able to be saved: #{ssid.errors.to_a.inspect}" unless ssid.save
      end

      ssid.update(ssid_info)
      access_point.seen!
    elsif obj[:type] == 'probe_request'
      client = PatronusFati::DataModels::Client.first(bssid: obj[:mac])

      return if client.nil?
      client.seen!

      return if obj[:ssid].nil? || obj[:ssid].empty?
      client.probes.first_or_create(essid: obj[:ssid])
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
      max_rate: attrs[:maxrate],

      last_seen_at: Time.now.to_i
    }.reject { |_, v| v.nil? }
  end
end
