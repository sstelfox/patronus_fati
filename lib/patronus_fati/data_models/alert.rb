module PatronusFati::DataModels
  class Alert
    include DataMapper::Resource

    property :id,  Serial

    property :last_seen_at, Time, { :default => Proc.new { Time.now } }
    timestamps :created_at
  end
end
