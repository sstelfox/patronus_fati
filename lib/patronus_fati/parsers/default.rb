
module PatronusFati
  module Parsers
    class Default
      def self.parse(data)
        strscan = StringScanner.new(data)
        results = []

        while e = strscan.scan_until(SERVER_DATA)
          results << e.scan(/[[:print:]]/).join.strip
        end

        results
      end
    end
  end
end
