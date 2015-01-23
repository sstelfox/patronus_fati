module PatronusFati::DataModels
  class Client
    include DataMapper::Resource

    property :id,  Serial
    property :mac, String

    property :last_seen_at, Time, :default => Proc.new { Time.now }
    timestamps :created_at

    belongs_to :access_point, :required => false
    has n, :probes
  end
end
