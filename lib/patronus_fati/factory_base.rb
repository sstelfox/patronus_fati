module PatronusFati
  # This module provides the basis for an automatic Factory registration and
  # generation system. Other modules that wish to make use of this
  # functionality should extend this module. Those modules should then in turn
  # be included by their respective generators.
  module FactoryBase
    # Turns the name of a class into it's snake cased equivalent.
    #
    # @param [Object] klass
    # @return [Symbol]
    def class_to_name(klass)
      klass.to_s.split('::').last.scan(/[A-Z][a-z]*/).map(&:downcase)
        .join('_').to_sym
    end

    # Factory method for triggering the lookup and return of the specific
    # requested type of factory.
    #
    # @param [Symbol] type Type of generator to create
    # @param [Hash<Symbol=>String>] options
    def factory(type, opts = {})
      return if ignored_types.include?(type)
      if registered_factories[type].nil?
        warn("Unknown factory #{type} (Available: #{registered_factories.keys})")
        #puts opts.inspect
        return
      end
      registered_factories[type].process(opts)
    end

    # Placeholder mechanism to allow sub-generators to not generate any
    # warnings for specific types.
    #
    # @return [Array<Symbol>]
    def ignored_types
      []
    end

    # Trigger for when this module gets included to register it with the
    # factory.
    #
    # @param [Object#create] klass
    # @return [Object]
    def included(klass)
      registered_factories[class_to_name(klass)] = klass
    end

    # Returns the hash containing the set of registered factories or
    # initializes it if one doesn't exist.
    #
    # @return [Hash<Symbol=>Object>]
    def registered_factories
      @registered_factories ||= {}
    end
  end
end
