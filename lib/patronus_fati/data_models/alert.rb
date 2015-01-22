module PatronusFati::DataModels
  class Alert
    include DataMapper::Resource

    property :id,  Serial

    timestamps :at
  end
end
