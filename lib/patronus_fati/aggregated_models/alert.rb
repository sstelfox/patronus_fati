module PatronusFati
  module AggregatedModels
    class Alert < AggregatedModelBase
      def self.find_or_create(attrs)
        key = Digest::SHA256.hexdigest('%s%i%s%s%s%0.6f' % [attrs[:bssid],
          attrs[:channel], attrs[:dest], attrs[:other], attrs[:source],
          attrs[:time]])

        instances[attrs[key]] || new(attrs)
      end

      attr_accessor :bssid, :channel, :dest, :other, :source, :text, :time

      def initialize(attrs)
        self.bssid   = attrs[:bssid]
        self.channel = attrs[:channel]
        self.dest   = attrs[:dest]
        self.other  = attrs[:other]
        self.source = attrs[:source]
        self.text = attrs[:text]
        self.time = Time.at(attrs[:time])

        save
      end

      def key
        Digest::SHA256.hexdigest('%s%i%s%s%s%0.6f' % [bssid, channel, dest,
          other, source, time.to_f])
      end
    end
  end
end
