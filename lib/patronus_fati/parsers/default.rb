
module PatronusFati
  module Parsers
    class Default
      def self.parse(resp)
        return unless resp =~ SERVER_RESPONSE
        Hash[SERVER_RESPONSE.names.zip(SERVER_RESPONSE.match(resp).captures)]
      end
    end
  end
end
