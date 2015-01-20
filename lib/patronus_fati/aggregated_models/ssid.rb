module PatronusFati
  module AggregatedModels
    class Ssid < AggregatedModelBase
      def self.find_or_create(attrs)
        instances[attrs[('%s:%s' % [attrs[:mac], attrs[:ssid]])]] || new(attrs)
      end

      attr_accessor :mac, :type, :ssid, :cryptset, :cloaked

      def initialize(attrs)
        self.cloaked = attrs[:cloaked]
        self.cryptset = attrs[:cryptset]
        self.mac = attrs[:mac]
        self.ssid = attrs[:ssid]
        self.type = attrs[:type]

        save
      end

      def key
        '%s:%s' % [mac, ssid]
      end
    end
  end
end
