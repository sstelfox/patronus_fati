module PatronusFati::DataModels
  class Probe
    include DataMapper::Resource

    property :client_id, Integer, :key => true
    property :essid,     String,  :key => true, :length => 64

    property :first_seen_at, DateTime, :default => Proc.new { DateTime.now }
    property :last_seen_at,  DateTime, :default => Proc.new { DateTime.now }

    belongs_to :client
  end
end
