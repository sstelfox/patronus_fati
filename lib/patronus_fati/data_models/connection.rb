module PatronusFati::DataModels
  class Connection
    include DataMapper::Resource

    default_scope(:default).update(:order => :connected_at.desc)

    property :id, Serial

    property :connected_at,    Time, :default => Proc.new { Time.now }
    property :disconnected_at, Time

    belongs_to :client
    belongs_to :access_point

    def disconnect!
      update(:disconnected_at => Time.now)
    end
  end
end
