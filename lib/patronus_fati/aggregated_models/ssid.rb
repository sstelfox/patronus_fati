module PatronusFati
  module AggregatedModels
    class Ssid < AggregatedModelBase
      def self.find(attrs)
        instances[attrs[('%s:%s' % [attrs[:mac], attrs[:ssid]])]]
      end

      attr_accessor :mac, :type, :ssid, :cryptset, :cloaked

      def key
        '%s:%s' % [mac, ssid]
      end

      def update(attrs)
        self.cloaked = attrs[:cloaked] || cloaked
        self.cryptset = attrs[:cryptset] || cryptset
        self.mac = attrs[:mac] || mac
        self.ssid = attrs[:ssid] || ssid
        self.type = attrs[:type] || type
      end
    end
  end
end
