module PatronusFati::DataModels
  class Mac
    include DataMapper::Resource

    property :id,     Serial

    property :mac,    String, :length => 17, :unique => true
    property :vendor, String, :length => 255

    has n, :access_points
    has n, :clients

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
  end
end
