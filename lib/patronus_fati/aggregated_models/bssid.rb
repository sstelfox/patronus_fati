module PatronusFati
  module AggregatedModels
    class Bssid < AggregatedModelBase
      def self.key; :bssid; end

      attr_accessor :bssid, :channel, :type
      alias :key :bssid

      def update(attrs)
        self.bssid = attrs[:bssid] || bssid
        self.channel = attrs[:channel] || channel
        self.type = attrs[:type] || type
      end
    end
  end
end
