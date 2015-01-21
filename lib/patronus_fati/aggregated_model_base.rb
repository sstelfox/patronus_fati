module PatronusFati
  class AggregatedModelBase
    def self.add_instance(inst)
      fail(ArgumentError, ('Not a %s' % self.to_s)) unless inst.is_a?(self)
      instances[inst.id_key] = inst if inst.valid?
    end

    def self.find(attrs)
      return unless id_key
      instances[id_key.call(attrs)]
    end

    def self.instances
      @instances ||= {}
    end

    def self.remove_instance(inst)
      instances.delete(inst.id_key)
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
        changed.push(k) unless changed.include?(k)
        @reportable_attributes[k] = v
        @state = :dirty unless @state == :new
      end
      self[k]
    end

    def attributes
      @reportable_attributes
    end

    def changed
      @changed_attributes
    end

    def changed?
      !changed.empty?
    end

    def expired?
      return false unless self.class.expiration_time || self[:last_seen].nil?
      (Time.now.to_i - self[:last_seen].to_i) > self.class.expiration_time
    end

    def flush
      @changed_attributes = []
      @state = :clean
    end

    def id_key
      self.class.id_key.call(self) if self.class.id_key rescue nil
    end

    def initialize(attrs = {})
      @changed_attributes = []
      @reportable_attributes = {first_seen: Time.now, last_seen: Time.now}
      @state = :new

      update(attrs)
    end

    def new?
      @state == :new
    end

    def update(attrs)
      self[:last_seen] = Time.now
      attrs.each { |key, val| self[key] = val }
      self.class.add_instance(self)
    end

    def valid?
      !id_key.nil?
    end

    protected

    def self.expiration_time(seconds = nil)
      @expiration_time = seconds if seconds
      @expiration_time
    end

    def self.id_key(attr = nil)
      @id_key = Proc.new { |inst| inst[attr] } if attr && !block_given?
      @id_key = Proc.new if block_given?
      @id_key
    end

    def self.reportable_attr(*attr_list)
      Array(attr_list).each do |attr|
        next unless attr.is_a?(Symbol)
        valid_attributes.push(attr)

        define_method(attr) { self[attr] }
        define_method("#{attr}=".to_sym) { |val| self[attr] = val }
      end
    end

    def self.valid_attributes
      @valid_attributes ||= []
    end
  end
end
