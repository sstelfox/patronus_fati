module PatronusFati::DataModels
  class Alert
    include DataMapper::Resource

    property :id,         Serial
    property :created_at, Integer,  :default => Proc.new { Time.now.to_i }
    property :message,    String,   :length => 255

    belongs_to :src_mac,   :model => 'Mac', :required => false
    belongs_to :dst_mac,   :model => 'Mac', :required => false
    belongs_to :other_mac, :model => 'Mac', :required => false

    def full_state
      {
        created_at: created_at,
        message: message,

        source: src_mac.mac,
        destination: dst_mac.mac,
        other: other_mac.mac
      }
    end
  end
end
