module PatronusFati::DataModels
  class Mac
    include DataMapper::Resource

    property :id,  Serial
    property :mac, String

    timestamps :at

    has n, :access_points, :child_key => [ :bssid_id ]
    has n, :clients
  end
end
