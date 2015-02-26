module PatronusFati::DataModels
  class Mac
    include DataMapper::Resource

    property :id,     Serial

    property :mac,    String, :length => 17, :unique => true
    property :vendor, String, :length => 255

    property :alert_count,        Integer, :default => 0
    property :clients_connected,  Integer, :default => 0
    property :active_ssids,       Integer, :default => 0
    property :is_client,          Boolean, :default => false
    property :connections_to_ap,  Integer, :default => 0

    has n, :access_points
    has n, :clients

    has n, :dst_alerts,   :model => 'Alert', :child_key => :dst_mac_id
    has n, :other_alerts, :model => 'Alert', :child_key => :other_mac_id
    has n, :src_alerts,   :model => 'Alert', :child_key => :src_mac_id

    before :save do
      next if self.vendor

      result = Louis.lookup(mac)
      self.vendor = result['long_vendor'] || result['short_vendor']
    end

    def is_ap?
      access_points.active.any?
    end

    def is_client?
      clients.active.any?
    end

    def update_cached_counts!
      update(
        alert_count:        (dst_alerts | other_alerts | src_alerts).count,
        active_ssids:       access_points.ssids.active.count,
        clients_connected:  access_points.connections.connected.count,
        connections_to_ap:  clients.connections.connected.count,
        is_client:          is_client?
      )
    end
  end
end
