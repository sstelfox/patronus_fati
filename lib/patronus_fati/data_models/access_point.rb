module PatronusFati::DataModels
  class AccessPoint
    include DataMapper::Resource

    property :id,      Serial
    property :bssid,   String,  :required => true
    property :type,    String,  :required => true
    property :channel, Integer, :required => true

    timestamps :at

    has n, :ssids
    has n, :connected_clients, 'Client', :child_key => [ :access_point_id ]
  end
end
