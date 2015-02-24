module PatronusFati::DataModels
  class ApFrequency
    include DataMapper::Resource

    property :mhz,              Integer,  :key => true,
                                          :required => true
    property :access_point_id,  Integer,  :key => true,
                                          :required => true
    property :packet_count,     Integer,  :default => 0,
                                          :required => true

    belongs_to :access_point
  end
end
