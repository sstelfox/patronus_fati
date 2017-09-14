module PatronusFati
  # This class holds two hours worth of presence data at minutely resolution.
  # Tests can be done to see whether or not whatever this is tracking was
  # present at a specific time or during a specific time interval.
  class Presence
    attr_accessor :current_presence, :first_seen, :last_presence, :window_start

    # How many seconds do each of our windows last
    WINDOW_LENGTH = 3600

    # How many intervals do we break each of our windows into? This must be
    # less than 64.
    WINDOW_INTERVALS = 60

    # How long each interval will last in seconds
    INTERVAL_DURATION = WINDOW_LENGTH / WINDOW_INTERVALS

    # Translate a timestamp relative to the provided reference window into an
    # appropriate bit within our bit field.
    def bit_for_time(reference_window, timestamp)
      offset = timestamp - reference_window
      raise ArgumentError if offset < 0 || offset > WINDOW_LENGTH
      (offset / INTERVAL_DURATION) + 1
    end

    # Get the bit representing our current interval within the window
    def current_bit_offset
      bit_for_time(current_window_start, Time.now.to_i)
    end

    # Returns the unix timestamp of the beginning of the current window.
    def current_window_start
      ts = Time.now.to_i
      ts - (ts % WINDOW_LENGTH)
    end

    # Returns true if we have no data points indicating we've seen the presence
    # of this instance in the entirety of our time window.
    def dead?
      rotate_presence
      current_presence.bits == 0 && last_presence.bits == 0
    end

    def initialize
      self.current_presence = BitField.new(WINDOW_INTERVALS)
      self.last_presence = BitField.new(WINDOW_INTERVALS)
      self.window_start = current_window_start
    end

    def last_window_start
      current_window_start - WINDOW_LENGTH
    end

    # Provides the beginning of the last interval when the tracked object was
    # seen. This could probably be optimized with a B tree search or the like
    # but this is more than enough for now.
    def last_visible
      rotate_presence

      return nil if dead?

      if (bit = current_presence.highest_bit_set)
        time_for_bit(current_window_start, bit)
      else
        time_for_bit(last_window_start, last_presence.highest_bit_set)
      end
    end

    # Mark the current interval as having been seen in the presence field. Will
    # handle rotation if the window has slipped.
    def mark_visible
      rotate_presence

      set_first_seen unless first_seen
      self.current_presence.set_bit(current_bit_offset)
    end

    # Should be called before reading or writing from/to the current_presence
    # to ensure it is pointing at the appropriate bitfield. When we shift into
    # a new bit window, this method will move the current window into the old
    # one, and reset the current bit field.
    def rotate_presence
      return if window_start == current_window_start

      self.last_presence = current_presence
      self.window_start = current_window_start
      self.current_presence = BitField.new(WINDOW_INTERVALS)
    end

    # Set the time we first saw whatever we're tracking to be the beginning of
    # the current interval. This prevents negative durations in the event we
    # only see it once.
    def set_first_seen
      cur_time = Time.now.to_i
      self.first_seen = cur_time - (cur_time % INTERVAL_DURATION)
    end

    # Translate a bit into an absolute unix time relative to the reference
    # window
    def time_for_bit(reference_window, bit)
      raise ArgumentError if bit <= 0 || bit > WINDOW_INTERVALS
      reference_window + (INTERVAL_DURATION * (bit - 1))
    end

    # Checks to see if the presence of the tracked object has been visible at
    # all since the provided time. Currently this is dependent on visible_at?
    # and can perform at most WINDOW_INTERVALS - 1 calls.
    #
    # This could be significantly sped up by a direct bit field check against
    # both the presence fields.
    def visible_since?(unix_time)
      rotate_presence

      return false unless (lv = last_visible)
      unix_time <= lv
    end

    # Returns the duration in seconds of how long the specific object was
    # absolutely seen. One additional interval duration is added to this length
    # as we consider to have seen the tracked object for the entire duration of
    # the interval not the length from the start of one interval to the start
    # of the last interval, which makes logical sense (1 bit set is 1 interval
    # duration, not zero seconds).
    def visible_time
      (last_visible + INTERVAL_DURATION) - first_seen if first_seen && last_visible
    end
  end
end
