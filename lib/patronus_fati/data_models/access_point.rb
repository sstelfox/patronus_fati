module PatronusFati::DataModels
  class AccessPoint
    include DataMapper::Resource

    property :id,      Serial
    property :bssid,   String,  :required => true
    property :type,    String,  :required => true
    property :channel, Integer, :required => true

    property :last_seen_at, Time, :default => Proc.new { Time.now }
    timestamps :created_at

    has n, :ssids, { :constraint => :destroy }
    has n, :connected_clients, 'Client', { :child_key => [ :access_point_id ], :constraint => :set_nil }
  end
end
