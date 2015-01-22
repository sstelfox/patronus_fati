module PatronusFati::DataModels
  class AccessPoint
    include DataMapper::Resource

    property :id,      Serial
    property :bssid,   String
    property :type,    String
    property :channel, Integer

    timestamps :at

    has n, :ssids
    has n, :connected_clients, 'Client', :child_key => [ :bssid_id ]
  end
end
