module PatronusFati
  module AggregatedModels
    class Bssid < AggregatedModelBase
      def self.key; :bssid; end

      attr_accessor :bssid, :channel, :type
      alias :key :bssid

      def initialize(attrs)
        self.bssid = attrs[:bssid]
        self.channel = attrs[:channel]
        self.type = attrs[:type]

        save
      end
    end
  end
end
