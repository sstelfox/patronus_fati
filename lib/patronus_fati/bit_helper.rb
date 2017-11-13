module PatronusFati
  module BitHelper
    # Count the consecutive number of bits in the provided number
    #
    # @param [Fixnum] num
    # @return [Fixnum]
    def self.count_consecutive_bits(num)
      count = 0
      while num != 0
        num = (num & (num << 1))
        count += 1
      end
      count
    end

    # This is a bit of an odd algorithm. It needs to find the length of the
    # longest common bits between n number of bit fields (in the context of
    # this program that is 64 bit numbers).
    #
    # The algorithm works by iterating over each bit field , and for each of
    # them calculating a reference bit field that is the combination of all
    # uncompared bit strings (those further down the list, prior ones will have
    # already been checked).
    #
    # By comparing the current bit list against the reference we can see where
    # that bit was present with at least one other bit from the other bit
    # field. Translating that into this domain specific context, was our SSID
    # announced at the same time as any other SSID for that minute (bit)?
    #
    # Once we have the comparison we can count the longest consecutive bits
    # between the current field and the reference field to find out how long
    # any given SSID was simultaneously transmitting as any other on the same
    # access point.
    #
    # This algorithm effectively has a computational cost of almost n^2 which
    # could potentially get nasty in the event of a huge number of active SSIDs
    # on a single AP. An upper limit should likely be decided on and in the
    # event it is reached an alternative method should likely be used (in our
    # case assuming it's broadcasting multiple is likely fine for these kinds
    # of floods).
    #
    # In the case that there is no overlap this will return 0.
    #
    # @param [Array<Fixnum>] bit_list
    # @return [Boolean]
    def self.largest_bit_overlap(bit_list)
      bit_list.map.with_index do |bits, i|
        # We're at the end of the list there are no bits to compare
        next 0 if bit_list.length == (i + 1)
        # Build a reference bit string of all the bit fields we haven't
        # compared this SSID to yet
        reference = bit_list[(i + 1)..-1].inject { |ref, bits| ref | bits }
        # Find the common bits between the reference and this bit string
        count_consecutive_bits(reference & bits)
      end.push(0).max
    end
  end
end
