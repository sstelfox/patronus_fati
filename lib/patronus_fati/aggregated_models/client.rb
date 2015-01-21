module PatronusFati
  module AggregatedModels
    class Client < AggregatedModelBase
      def self.key; :mac; end

      attr_accessor :bssid, :channel, :mac, :type
      alias :key :mac

      def update(attrs)
        self.bssid = attrs[:bssid] || bssid
        self.channel = attrs[:channel] || channel
        self.mac = attrs[:mac] || mac
        self.type = attrs[:type] || type
      end
    end
  end
end
