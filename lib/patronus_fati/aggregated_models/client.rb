module PatronusFati
  module AggregatedModels
    class Client
      def self.add_instance(inst)
        fail(ArgumentError, ('Not a %s' % self.to_s)) unless inst.is_a?(self)
        instances[inst.key] = inst
      end

      def self.find_or_create(attrs)
        instances[attrs[:mac]] || new(attrs)
      end

      def self.instances
        @instances ||= {}
      end

      attr_accessor :bssid, :channel, :mac, :type

      def initialize(attrs)
        self.bssid = attrs[:bssid]
        self.channel = attrs[:channel]
        self.mac = attrs[:mac]
        self.type = attrs[:type]

        save
      end

      alias :key :mac

      def save
        fail(KeyError, 'Invalid Client Model') unless valid?
        self.class.add_instance(self)
      end

      def valid?
        !key.nil?
      end
    end
  end
end
