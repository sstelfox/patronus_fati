module PatronusFati::DataModels
  class Client
    include DataMapper::Resource

    property :id,  Serial
    property :mac, String

    timestamps :at
  end
end
