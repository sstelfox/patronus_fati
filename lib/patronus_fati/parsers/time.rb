
module PatronusFati
  module Parsers
    class TIME
      @@headers = ["timestamp"]

      def self.parse(data)
        strscan = StringScanner.new(data)
        results = []

        while e = strscan.scan_until(SERVER_DATA)
          results << e.scan(/[[:print:]]/).join.strip
        end

        Hash[@@headers.zip(results)]
      end
    end
  end
end
