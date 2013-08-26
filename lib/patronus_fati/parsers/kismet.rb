
module PatronusFati
  module Parsers
    class KISMET
      @@headers = ["version", "start_time", "build_revision", "command_id"]

      def self.parse(data)
        strscan = StringScanner.new(data)
        results = []

        while e = strscan.scan_until(SERVER_DATA)
          results << e.scan(/[[:print:]]/).join.strip
        end

        Hash[@@headers.zip(results)].merge({"type" => "kismet"})
      end
    end
  end
end
