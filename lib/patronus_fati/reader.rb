
module PatronusFati
  class Reader
    def initialize(socket, parser)
      @buffer = StringScanner.new("")
      @parser = parser
      @socket = socket
    end

    # Parse all the whole lines out of the buffer
    def parse_buffer
      messages = []
      while line = @buffer.scan_until(/^.+?\r?\n/)
        messages << @parser.parse(line.strip)
      end
      messages
    end

    def buffer_available_data
      # Make sure we're not going to act on a closed socket
      return if @socket.closed?

      # Check to see if there is any data for us to read...
      ready_socket = IO.select([@socket], nil, nil, 0)
      if ready_socket && ready_socket.first.first == @socket
        # Yes there is, add what we can to the buffer
        begin
          @buffer.string = (@buffer.rest + @socket.read_nonblock(2048))
        rescue Errno::EAGAIN, Errno::EWOULDBLOCK
          # Socket would block, try again later
        end
      end
    end
  end
end

