module PatronusFati
  module MessageProcessor
    module Protocols
      include MessageProcessor

      def self.process(obj)
        obj.protocols.split(',').map { |p| "CAPABILITY #{p}" }
      end
    end
  end
end
