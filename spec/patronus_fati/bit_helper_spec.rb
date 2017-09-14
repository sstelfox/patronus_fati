require 'spec_helper'

RSpec.describe(PatronusFati::BitHelper) do
  context '#count_consecutive_bits' do
    let(:test_set) do
      [
        { bits: "00000000", answer: 0 },
        { bits: "11111111", answer: 8 },
        { bits: "11001111", answer: 4 },
        { bits: "10101010", answer: 1 }
      ]
    end

    it 'should correctly count varying number of consecutive bits in a number' do
      test_set.each do |set|
        num = set[:bits].to_i(2)
        expect(described_class.count_consecutive_bits(num)).to eql(set[:answer])
      end
    end
  end

  context '#largest_bit_overlap' do
    let(:test_set) do
      [
        {
          bit_strings: [
            "000000000000000000000000",
            "000011100000111000001110",
            "001111000011110000111100",
            "111111111111111111111111"
          ],
          answer: 4
        },
        {
          bit_strings: [
            "0000"
          ],
          answer: 0
        },
        {
          bit_strings: [
            "1111111111111111",
            "1111111111111111",
            "0000000000000000"
          ],
          answer: 16
        }
      ]
    end

    it 'should correctly find the longest run of overlapping bits' do
      test_set.each do |set|
        nums = set[:bit_strings].map { |bs| bs.to_i(2) }
        expect(described_class.largest_bit_overlap(nums)).to eql(set[:answer])
      end
    end
  end
end
