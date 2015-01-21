module PatronusFati
  class AggregatedModelBase
    def self.add_instance(inst)
      fail(ArgumentError, ('Not a %s' % self.to_s)) unless inst.is_a?(self)
      instances[inst.key] = inst
    end

    def self.find(attrs)
      instances[attrs[key]]
    end

    def self.update_or_create(attrs)
      return new(attrs) unless (inst = find(attrs))
      inst.update(attrs)
    end

    def self.instances
      @instances ||= {}
    end

    def initialize(attrs = {})
      update(attrs)
      save
    end

    def save
      fail(KeyError, 'Invalid model') unless valid?
      self.class.add_instance(self)
    end

    def valid?
      !key.nil?
    end
  end
end
