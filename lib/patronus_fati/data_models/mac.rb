module PatronusFati::DataModels
  class Mac
    include DataMapper::Resource

    property :id, Serial
    property :mac, String, :length => 17, :unique => true

    has n, :access_points
    has n, :clients

    has n, :src_alerts, :model => 'Alert', :child_key => :src_mac_id
    has n, :dst_alerts, :model => 'Alert', :child_key => :dst_mac_id
    has n, :other_alerts, :model => 'Alert', :child_key => :other_mac_id
  end
end
