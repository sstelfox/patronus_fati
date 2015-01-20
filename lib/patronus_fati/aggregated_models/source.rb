module PatronusFati
  module AggregatedModels
    class Source
      def self.add_instance(inst)
        fail(ArgumentError, ('Not a %s' % self.to_s)) unless inst.is_a?(self)
        instances[inst.key] = inst
      end

      def self.find_or_create(attrs)
        instances[attrs[:uuid]] || new(attrs)
      end

      def self.instances
        @instances ||= {}
      end

      attr_accessor :interface, :type, :uuid

      def initialize(attrs)
        self.uuid = attrs[:uuid]
        self.interface = attrs[:interface]
        self.type = attrs[:type]

        save
      end

      alias :key :uuid

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
