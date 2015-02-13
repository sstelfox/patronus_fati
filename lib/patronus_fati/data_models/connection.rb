module PatronusFati::DataModels
  class Connection
    include DataMapper::Resource

    default_scope(:default).update(:order => :connected_at.desc)

    property :id, Serial

    property :connected_at,    DateTime, :default => Proc.new { DateTime.now }
    property :disconnected_at, DateTime

    belongs_to :client
    belongs_to :access_point

    def active?
      disconnected_at.nil?
    end

    def self.active
      all(:disconnected_at => nil)
    end

    def self.inactive
      all(:disconnected_at.not => nil)
    end

    def disconnect!
      update(:disconnected_at => DateTime.now)
    end
  end
end
