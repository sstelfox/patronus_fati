module PatronusFati::DataModels
  class Client
    include DataMapper::Resource

    property :id,  Serial
    property :mac, String

    belongs_to :access_point, :required => false
    has n, :probes

    timestamps :at
  end
end
