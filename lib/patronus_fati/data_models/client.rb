module PatronusFati::DataModels
  class Client
    include DataMapper::Resource

    property :id,  Serial

    timestamps :at

    belongs_to :mac
  end
end
