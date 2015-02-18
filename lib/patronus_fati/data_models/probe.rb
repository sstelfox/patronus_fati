module PatronusFati::DataModels
  class Probe
    include DataMapper::Resource

    property :client_id, Integer, :key => true
    property :essid,     String,  :key => true, :length => 64

    property :first_seen_at, Integer, :default => Proc.new { Time.now.to_i }
    property :last_seen_at,  Integer, :default => Proc.new { Time.now.to_i }

    belongs_to :client
  end
end
