
module PatronusFati
  class ParseFactory
    def initialize(client = nil)
      @client = client
    end

    def parse(line)
      return unless line =~ SERVER_RESPONSE
      message = Hash[SERVER_RESPONSE.names.zip(SERVER_RESPONSE.match(line).captures)]

      if PatronusFati::Parsers.const_defined?(message["header"].to_sym)
        PatronusFati::Parsers.const_get(message["header"].to_sym).parse(message["data"])
      else
        { "type" => message["header"].downcase, "data" => PatronusFati::Parsers::Default.parse(message["data"]) }
      end
    end
  end
end
