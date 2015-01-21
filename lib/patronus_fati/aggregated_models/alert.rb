module PatronusFati
  module AggregatedModels
    class Alert < AggregatedModelBase
      def self.find(attrs)
        key = Digest::SHA256.hexdigest('%s%i%s%s%s%0.6f' % [attrs[:bssid],
          attrs[:channel], attrs[:dest], attrs[:other], attrs[:source],
          attrs[:time]])

        instances[attrs[key]]
      end

      attr_accessor :bssid, :channel, :dest, :other, :source, :text, :time

      def key
        Digest::SHA256.hexdigest('%s%i%s%s%s%0.6f' % [bssid, channel, dest,
          other, source, time.to_f])
      end

      def update(attrs)
        self.bssid   = attrs[:bssid] || bssid
        self.channel = attrs[:channel] || channel
        self.dest   = attrs[:dest] || dest
        self.other  = attrs[:other] || other
        self.source = attrs[:source] || source
        self.text = attrs[:text] || text
        self.time = Time.at(attrs[:time]) || time
      end
    end
  end
end
