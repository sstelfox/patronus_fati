module PatronusFati::DataModels
  class ApSignal
    include DataMapper::Resource

    property :id,           Serial
    property :timestamp,    Integer,  :default => Proc.new { Time.now.to_i },
                                      :required => true
    property :dbm,          Integer,  :required => true

    belongs_to :access_point
  end
end
