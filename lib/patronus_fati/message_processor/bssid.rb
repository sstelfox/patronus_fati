module PatronusFati::MessageProcessor::Bssid
  include PatronusFati::MessageProcessor

  def self.process(obj)
    useful_data = obj.attributes.select { |k, v| !v.nil? && [:bssid, :channel, :type].include?(k) }

    puts obj[:type]
    access_point = PatronusFati::DataModels::AccessPoint.first_or_create({bssid: obj[:bssid]}, useful_data)
    access_point.update(useful_data)

    nil
  end
end
