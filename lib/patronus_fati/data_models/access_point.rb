module PatronusFati::DataModels
  class AccessPoint
    include DataMapper::Resource

    property :id,  Serial

    timestamps :at

    belongs_to :bssid, 'Mac'
  end
end
