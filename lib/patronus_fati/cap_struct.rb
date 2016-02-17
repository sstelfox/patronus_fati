module PatronusFati
  # Class generator similar to a struct but allows for using a hash as an
  # unordered initializer. This was designed to work as an initializer for
  # capability classes and thus has a few additional methods written in to
  # support this functionality.
  module CapStruct
    # Creates a new dynamic class with the provided attributes.
    #
    # @param [Array<Symbol>] args The list of attributes of getters and
    #   setters.
    def self.new(*args)
      Class.new do
        @attributes_keys = args.map(&:to_sym).dup.freeze
        @supported_keys = []

        # Any unspecified data filter will default to just returning the same
        # value passed in.
        @data_filters = Hash.new(Proc.new { |i| i })

        # Returns the keys that are valid for this class (effectively it's
        # attributes)
        #
        # @return [Array<Symbol>]
        def self.attribute_keys
          @attributes_keys
        end

        # Call and return the resulting value of the data filter requested.
        #
        # @param [Symbol] attr
        # @param [Object] value
        # @return [Object]
        def self.data_filter(attr, value)
          @data_filters[attr].call(value)
        end

        # Set the data filter to the provided block.
        #
        # @param [Symbol] attr
        def self.set_data_filter(*attr)
          blk = Proc.new
          Array(attr).each { |a| @data_filters[a] = blk }
        end

        # Return the intersection of our known attribute keys and the keys that
        # the server has claimed to support. The order is important to be
        # consistent between all returned runs of this.
        #
        # @return [Array<Symbol>]
        def self.enabled_keys
          attribute_keys & supported_keys
        end

        # Return the keys the server has claimed to support (and maintain the order).
        #
        # @return [Array<Symbol>]
        def self.supported_keys
          @supported_keys
        end

        # Set the keys supported by the server.
        #
        # @param [Array<Symbol>] sk
        def self.supported_keys=(sk)
          @supported_keys = sk
        end

        attr_reader :attributes

        def [](key)
          @attributes[key.to_sym]
        end

        def []=(key, val)
          if self.class.attribute_keys.include?(key.to_sym)
            @attributes[key.to_sym] = self.class.data_filter(key.to_sym, val)
          end
        rescue => e
          fail(PatronusFati::ParseError, format("An error occurred parsing field %s on a %s message. Value was '%s'", key, self.class.to_s, val.dump))
        end

        # Configure and setup the instance with all the valid parameters for
        # the dynamic class.
        #
        # @attrs [Symbol=>Object] attrs
        def initialize(attrs)
          @attributes = {}
          attrs.each { |k, v| self[k] = v }
        end

        # Define all the appropriate setters and getters for this dynamic class.
        args.each do |a|
          define_method(a.to_sym) { self[a] }
          define_method("#{a}=".to_sym) { |val| self[a] = val }
        end
      end
    end
  end
end
