module PatronusFati::DataModels
  class Alert
    include DataMapper::Resource

    property :id,         Serial
    property :created_at, Time, { :default => Proc.new { Time.now } }
    property :message,    String, :length => 255

    belongs_to :src_mac,   :model => 'Mac', :required => false
    belongs_to :dst_mac,   :model => 'Mac', :required => false
    belongs_to :other_mac, :model => 'Mac', :required => false
  end
end
