module PatronusFati
  # This class holds two hours worth of presence data at minutely resolution.
  # Tests can be done to see whether or not whatever this is tracking was
  # present at a specific time or during a specific time interval.
  class Presence
    attr_accessor :current_presence, :last_presence, :window_start

    # How many seconds do each of our windows last
    WINDOW_LENGTH = 3600

    # How many intervals do we break each of our windows into? This must be
    # less than 64.
    WINDOW_INTERVALS = 60

    INTERVAL_DURATION = WINDOW_LENGTH / WINDOW_INTERVALS

    # Get the bit representing our current interval within the window
    def current_bit_offset
      (Time.now.to_i - current_window) / INTERVAL_DURATION
    end

    # Returns the unix timestamp of the beginning of the current window.
    def current_window
      ts = Time.now.to_i
      ts - (ts % WINDOW_LENGTH)
    end

    def initialize
      self.current_presence = 0
      self.last_presence = 0
      self.window_start = current_window
    end

    def last_window_start
      window_start - WINDOW_LENGTH
    end

    # Mark the current interval as having been seen in the presence field. Will
    # handle rotation if the window has slipped.
    def mark_visible
      rotate_presence
      self.current_presence |= (1 << current_bit_offset)
    end

    # Should be called before reading or writing from/to the current_presence
    # to ensure it is pointing at the appropriate bitfield. When we shift into
    # a new bit window, this method will move the current window into the old
    # one, and reset the current bit field.
    def rotate_presence
      return if window_start == current_window

      self.last_presence = current_presence
      self.window_start = current_window
      self.current_presence = 0
    end

    # Check whether or not we had seen the presence of what we're tracking at
    # the specific time. If it was seen at all during the interval encompassing
    # the provided time it will return true, otherwise false. If the provided
    # time is outside of our tracking range this will return false.
    def visible_at?(unix_time)
      rotate_presence

      if unix_time >= window_start
        bit_offset = (unix_time - window_start) / INTERVAL_DURATION
        window = current_presence
      else
        bit_offset = (unix_time - last_window_start) / INTERVAL_DURATION
        window = last_presence
      end

      # Out of our visible range
      return false if bit_offset < 0 || bit_offset >= WINDOW_INTERVALS

      (window & (1 << bit_offset)) > 0
    end

    # Checks to see if the presence of the tracked object has been visible at
    # all since the provided time. Currently this is dependent on visible_at?
    # and can perform at most WINDOW_INTERVALS - 1 calls.
    #
    # This could be significantly sped up by a direct bit field check against
    # both the presence fields.
    def visible_since?(unix_time)
      current = unix_time - (unix_time % INTERVAL_DURATION)
      return false if current > Time.now.to_i

      # Shortcut our time ranges
      if current <= last_window_start
        return last_presence > 0 || current_presence > 0
      elsif current < window_start
        # We can quickly check if it's been seen at all in the entirety of the
        # current_presence
        return true if current_presence > 0

        # Only the remainder of the last_presence needs to be checked...
        while current < window_start
          return true if visible_at?(current)
          current += INTERVAL_DURATION
        end
      else
        # Only the time between the call and the end of the current window
        # needs to be checked now
        window_end = window_start + WINDOW_LENGTH
        while current < window_end
          return true if visible_at?(current)
          current += INTERVAL_DURATION
        end
      end

      false
    end
  end
end
