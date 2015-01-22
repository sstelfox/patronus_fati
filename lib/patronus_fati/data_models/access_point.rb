module PatronusFati::DataModels
  class AccessPoint
    include DataMapper::Resource

    property :id,    Serial
    property :bssid, String

    timestamps :at

    has n, :ssids
  end
end
