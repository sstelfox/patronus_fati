module PatronusFati
  module MessageProcessor
    module Capability
      include MessageProcessor

      def self.process(obj)
        # The capability detection for the capability command is broken. It
        # returns the name of the command followed by the capabilities but the
        # result of a request ignores that it also sends back the name of the
        # command. We don't want to mess up our parsing so we work around it by
        # ignoring these messages.
        return if obj.name == 'CAPABILITY'
        return unless PatronusFati::MessageModels.const_defined?(obj.name.downcase.capitalize)

        target_cap = PatronusFati::MessageModels.const_get(obj.name.downcase.capitalize)
        target_cap.supported_keys = obj.capabilities.split(',').map(&:to_sym)

        keys_to_enable = target_cap.enabled_keys.map(&:to_s).join(',')

        # Return the response to the server
        "ENABLE #{obj.name} #{keys_to_enable}"
      end
    end
  end
end
