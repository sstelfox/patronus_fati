module PatronusFati::DataModels
  class Broadcast
    include DataMapper::Resource

    default_scope(:default).update(:order => :last_seen_at.desc)

    property :id, Serial

    property :first_seen_at,  Time, :default => Proc.new { Time.now }
    property :last_seen_at,   Time

    belongs_to :access_point
    belongs_to :ssid

    def seen!
      update(:last_seen_at => Time.now)
    end
  end
end
