module PatronusFati::MessageProcessor::Alert
  include PatronusFati::MessageProcessor

  def self.process(obj)
    src_mac = PatronusFati::DataModels::Mac.first_or_create(mac: obj[:source])
    dst_mac = PatronusFati::DataModels::Mac.first_or_create(mac: obj[:dest])
    other_mac = PatronusFati::DataModels::Mac.first_or_create(mac: obj[:other])

    PatronusFati::DataModels::Alert.first_or_create({created_at: obj.sec, \
      message: obj[:text]}, {created_at: obj.sec, message: obj[:text], \
      src_mac: src_mac, dst_mac: dst_mac, other_mac: other_mac})

    nil
  end
end
