module PatronusFati::DataModels
  class ClientFrequency
    include DataMapper::Resource

    property :mhz,          Integer,  :key => true,
                                      :required => true
    property :client_id,    Integer,  :key => true,
                                      :required => true
    property :packet_count, Integer,  :default => 0,
                                      :required => true

    belongs_to :client
  end
end
