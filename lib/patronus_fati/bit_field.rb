module PatronusFati
  class BitField
    attr_accessor :bits, :tracked_count

    def any_set_in?(rng)
      rng.find { |i| bit_set?(i) }
    end

    def bit_set?(bit)
      raise ArgumentError, "Bit #{bit} is out of range of #{tracked_count}" unless valid_bit?(bit)
      (bits & (1 << (bit - 1))) > 0
    end

    def highest_bit_set
      return nil if bits == 0
      tracked_count.times.reverse_each.find { |i| bit_set?(i + 1) } + 1
    end

    def initialize(count)
      raise ArgumentError if count <= 0

      self.bits = 0
      self.tracked_count = count
    end

    def lowest_bit_set
      return nil if bits == 0
      tracked_count.times.each.find { |i| bit_set?(i + 1) } + 1
    end

    def set_bit(bit)
      raise ArgumentError unless valid_bit?(bit)
      self.bits |= (1 << bit - 1)
    end

    def valid_bit?(bit)
      bit > 0 && bit <= tracked_count
    end

    def to_s
      bits.to_s(2).rjust(tracked_count, '0')
    end
  end
end
