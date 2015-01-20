module PatronusFati
  module AggregatedModels
    class Bssid
      def self.add_instance(inst)
        fail(ArgumentError, ('Not a %s' % self.to_s)) unless inst.is_a?(self)
        instances[inst.key] = inst
      end

      def self.find_or_create(attrs)
        instances[attrs[:bssid]] || new(attrs)
      end

      def self.instances
        @instances ||= {}
      end

      attr_accessor :bssid, :channel, :type

      def initialize(attrs)
        self.bssid = attrs[:bssid]
        self.channel = attrs[:channel]
        self.type = attrs[:type]

        save
      end

      alias :key :bssid

      def save
        fail(KeyError, 'Invalid Source Model') unless valid?
        self.class.add_instance(self)
      end

      def valid?
        !key.nil?
      end
    end
  end
end
