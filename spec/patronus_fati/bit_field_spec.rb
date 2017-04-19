require 'spec_helper'

RSpec.describe(PatronusFati::BitField) do
  let(:bit_count) { rand(63) + 1 }
  subject { described_class.new(bit_count) }

  context '#bit_set?' do
    let(:bit_count) { 23 }
    subject { described_class.new(bit_count) }

    it 'should return true if the bit is set' do
      subject.bits = 8
      expect(subject.bit_set?(4)).to be_truthy
    end

    it 'should return false if the bit is clear' do
      subject.bits = 0
      expect(subject.bit_set?(1)).to be_falsey
    end

    it 'should raise an error if the bit provided is larger than we\'re tracking' do
      expect { subject.bit_set?(bit_count + 1) }.to raise_error(ArgumentError)
    end

    it 'should raise an error if the bit is less than zero' do
      expect { subject.bit_set?(-1) }.to raise_error(ArgumentError)
    end
  end

  context '#highest_bit_set' do
    it 'should return nil if no bits are set' do
      subject.bits = 0
      expect(subject.highest_bit_set).to be_nil
    end

    it 'should return the bit number of the highest bit set' do
      subject = described_class.new(8)
      subject.bits = 8 | 1 # Bits 1 & 4 are set
      expect(subject.highest_bit_set).to eql(4)
    end
  end

  context '#initialize' do
    it 'should initialize the bits to zero' do
      expect(subject.bits).to eql(0)
    end

    it 'should set the number of bits being tracked to the provided value' do
      expect(subject.tracked_count).to eql(bit_count)
    end

    it 'should not allow 0 or fewer bits to be tracked' do
      expect { described_class.new(0) }.to raise_error(ArgumentError)
      expect { described_class.new(rand(50) * -1) }.to raise_error(ArgumentError)
    end
  end

  context '#lowest_bit_set' do
    it 'should return nil if no bits are set' do
      subject.bits = 0
      expect(subject.lowest_bit_set).to be_nil
    end

    it 'should return the bit number of the lowest bit set' do
      subject = described_class.new(8)
      subject.bits = 8 | 1 # Bits 1 & 4 are set
      expect(subject.lowest_bit_set).to eql(1)
    end
  end

  context '#set_bit' do
    let(:bit_count) { 10 }
    subject { described_class.new(bit_count) }

    it 'should raise an error if the bit provided is less than 0' do
      expect { subject.set_bit(-1) }.to raise_error(ArgumentError)
    end

    it 'should raise an error if the bit provided is larger than we\'re tracking' do
      expect { subject.set_bit(bit_count + 1) }.to raise_error(ArgumentError)
    end

    it 'should only set the provided bit' do
      expect { subject.set_bit(5) }.to change { subject.bits }.from(0).to(16)
    end

    it 'should not change anything if the bit is already set' do
      subject.bits = 212
      expect { subject.set_bit(7) }.to_not change { subject.bits }
    end
  end

  context '#to_s' do
    it 'should always be the length of bits being counted' do
      expect(subject.to_s.length).to eql(bit_count)
    end

    it 'should consist of all zeros when nothing has been set' do
      subject = described_class.new(8)

      expect(subject.to_s).to eql('00000000')
    end

    it 'should consist of all ones when everything has been set' do
      subject = described_class.new(5)
      subject.bits = 31 # 2^6 - 1

      expect(subject.to_s).to eql('11111')
    end

    it 'should have the correct bit set in LSB format' do
      subject = described_class.new(10)
      subject.bits = 16 # 5th bit set

      expect(subject.to_s).to eql('0000010000')
    end
  end

  context '#valid_bit?' do
    let(:bit_count) { 12 }
    subject { described_class.new(bit_count) }

    it 'should return false if the bit is zero or less' do
      expect(subject.valid_bit?(0)).to be_falsey
      expect(subject.valid_bit?(-1)).to be_falsey
    end

    it 'should return false if the bit is higher than we\'re tracking' do
      expect(subject.valid_bit?(14)).to be_falsey
    end

    it 'should return true if the bit is within the appropriate range' do
      expect(subject.valid_bit?(8)).to be_truthy
    end
  end
end
