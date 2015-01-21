module PatronusFati
  class AggregatedModelBase
    def self.add_instance(inst)
      fail(ArgumentError, ('Not a %s' % self.to_s)) unless inst.is_a?(self)
      instances[inst.key] = inst
    end

    def self.find(attrs)
      return unless key
      instances[key.call(attrs)]
    end

    def self.instances
      @instances ||= {}
    end

    def self.remove_instance(inst)
      instances.delete(inst.key)
    end

    def self.update_or_create(attrs)
      inst = find(attrs) || new
      inst.update(attrs)
    end

    def [](k)
      @reportable_attributes[k]
    end

    def []=(k, v)
      return unless self.class.valid_attributes.include?(k)
      if self[k] != v
        changed.push(k) if changed.include?(k)
        @reportable_attributes[k] = v
      end
      self[k]
    end

    def changed
      @changed_attributes
    end

    def changed?
      !changed.empty?
    end

    def expired?
      return false unless self.class.expiration || self[:last_seen].nil?
      (Time.now.to_i - self[:last_seen].to_i) > self.class.expiration
    end

    def initialize(attrs = {})
      @changed_attributes = []
      @reportable_attributes = {}
      @valid_attributes = []

      update(attrs)

      self.class.add_instance(self)
    end

    def key
      self.class.key.call(self) if self.class.key
    end

    def flush
      @changed_attributes = []
    end

    def update(attrs)
      atrrs.each { |key, val| self[key] = val }
    end

    protected

    def self.expiration_time(seconds = nil)
      @expiration_time = seconds if seconds
      @expiration_time
    end

    def self.key(attr = nil)
      @key = Proc.new { |inst| inst[attr] } if attr && !block_given?
      @key = Proc.new if block_given?
      @key
    end

    def self.reportable_attr(*attr_list)
      Array(attr_list).each do |attr|
        next unless attr.is_a?(Symbol)
        @valid_attributes.push(attr)

        define_method(attr) { self[attr] }
        defint_method("#{attr}=".to_sym) { |val| self[attr] = val }
      end
    end

    def self.valid_attributes
      @valid_attributes
    end
  end
end
