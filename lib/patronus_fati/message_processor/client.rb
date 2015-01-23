module PatronusFati::MessageProcessor::Client
  include PatronusFati::MessageProcessor

  def self.process(obj)
    client = PatronusFati::DataModels::Client.first_or_create({mac: obj[:mac]})

    # Handle the associations
    client.update(access_point: nil) if obj[:bssid].nil?
    if obj[:bssid] && obj[:bssid] != obj[:mac]
      ap = PatronusFati::DataModels::AccessPoint.first(bssid: obj[:bssid])
      client.update(access_point: ap)
    end

    nil
  end
end
