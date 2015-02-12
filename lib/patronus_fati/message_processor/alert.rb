module PatronusFati::MessageProcessor::Alert
  include PatronusFati::MessageProcessor

  def self.process(obj)
    time = Time.at(('%i.%i' % [obj.sec, obj.usec]).to_f)

    src_mac = PatronusFati::DataModels::Mac.first_or_create(mac: obj[:source])
    dst_mac = PatronusFati::DataModels::Mac.first_or_create(mac: obj[:dest])
    other_mac = PatronusFati::DataModels::Mac.first_or_create(mac: obj[:other])

    PatronusFati::DataModels::Alert.first_or_create({created_at: time, \
      message: obj[:text]}, {created_at: time, message: obj[:text], \
      src_mac: src_mac, dst_mac: dst_mac, other_mac: other_mac})

    nil
  end
end
