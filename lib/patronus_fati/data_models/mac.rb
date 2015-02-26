module PatronusFati::DataModels
  class Mac
    include DataMapper::Resource

    property :id,     Serial

    property :mac,    String, :length => 17, :unique => true
    property :vendor, String, :length => 255

    property :alert_count,              Integer, :default => 0
    property :ap_connections_count,     Integer, :default => 0
    property :ssid_count,               Integer, :default => 0
    property :client_count,             Integer, :default => 0
    property :client_connections_count, Integer, :default => 0

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

    def update_cached_counts!
      update(
        alert_count: (dst_alerts.map(&:id) | other_alerts.map(&:id) | src_alerts.map(&:id)).count,
        ap_connections_count: access_points.connections.connected.count,
        ssid_count: access_points.active.ssids.count,
        client_count: clients.active.count,
        client_connections_count: clients.connections.connected.count
      )
    end
  end
end
