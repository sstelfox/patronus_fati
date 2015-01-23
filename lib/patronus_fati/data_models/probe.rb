module PatronusFati::DataModels
  class Probe
    include DataMapper::Resource

    property :id,   Serial
    property :name, String

    property :last_seen_at, Time, :default => Proc.new { Time.now }
    timestamps :created_at

    belongs_to :client
  end
end
