
require 'minitest/unit'

class KismetMessageParserTest < MiniTest::Unit::TestCase
  def initialize(*args)
    super
    @sample_line = "*KISMET: 0.0.0 1377500000 kismet01.example.org pcapdump,netxml,nettxt,gpsxml,alert 0"
  end

  def test_parse_hash
    output = PatronusFati::Parsers::KISMET.parse(@sample_line)
    assert output.kind_of?(Hash)
  end
end
