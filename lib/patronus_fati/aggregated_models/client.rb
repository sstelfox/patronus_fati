module PatronusFati
  module AggregatedModels
    class Client < AggregatedModelBase
      def self.key; :mac; end

      attr_accessor :bssid, :channel, :mac, :type
      alias :key :mac

      def initialize(attrs)
        self.bssid = attrs[:bssid]
        self.channel = attrs[:channel]
        self.mac = attrs[:mac]
        self.type = attrs[:type]

        save
      end
    end
  end
end
