
module PatronusFati
  class ParseFactory
    def self.parse(line)
      strscan = StringScanner.new(line)
      results = []

      while e = strscan.scan_until(PatronusFati::SERVER_DATA)
        results << e.scan(/[[:print:]]/).join.strip
      end

      results.map do |r|
        PatronusFati::Parsers::Default.parse(line)
      end
    end
  end
end
