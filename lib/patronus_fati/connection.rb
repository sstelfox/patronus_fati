module PatronusFati
  class Connection
    attr_reader :port, :read_queue, :server, :write_queue

    def initialize(server, port)
      @server = server
      @port = port
    end

    def connect
      establish_connection

      self.read_queue = Queue.new
      self.write_queue = Queue.new

      start_read_thread
      start_write_thread
    end

    def connected?
      !socket.nil?
    end

    def disconnect
      return unless connected?

      Thread.kill(read_thread)
      Thread.kill(write_thread)

      socket.close

      self.socket = nil
      self.read_queue = nil
      self.write_queue = nil
    end

    def write(msg)
      write_queue.push(msg)
    end

    protected

    attr_accessor :read_thread, :socket, :write_thread
    attr_writer :read_queue, :write_queue

    def establish_connection
      return if connected?
      @socket = TCPSocket.new(server, port)
    end

    def start_read_thread
      self.read_thread = Thread.new do
        begin
          while (line = socket.readline)
            read_queue << line
          end
        rescue Timeout::Error
          # Connection timed out...
          exit 1
        rescue EOFError
          # We lost our connection...
          exit 2
        rescue => e
          puts ('Unknown issue reading from socket: %s' % e.message)
          exit 3
        end
      end
    end

    def start_write_thread
      self.write_thread = Thread.new do
        begin
          while (msg = write_queue.pop)
            socket.puts(msg)
          end
        rescue => e
          puts ('Unknown issue writing to socket: %s' % e.message)
          exit 1
        end
      end
    end
  end
end
