module PatronusFati::DataModels
  class Probe
    include DataMapper::Resource

    property :id,   Serial
    property :name, String

    belongs_to :client

    timestamps :at
  end
end
