module PatronusFati
  PatronusFatiError = Class.new(StandardError)
  LostConnection    = Class.new(PatronusFatiError)
  ConnectionTimeout = Class.new(PatronusFatiError)
  UnableToRead      = Class.new(PatronusFatiError)
  UnableToWrite     = Class.new(PatronusFatiError)

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

      socket.close unless socket.closed?

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
        rescue Timeout::Error => e
          socket.close
          raise ConnectionTimeout, e.message
        rescue EOFError => e
          socket.close
          raise LostConnection, e.message
        rescue => e
          socket.close
          raise UnableToRead, e.message
        end
      end
    end

    def start_write_thread
      self.write_thread = Thread.new do
        begin
          count = 0
          while (msg = write_queue.pop)
            socket.write("!%i %s\r\n" % [count, msg])
            count += 1
          end
        rescue => e
          socket.close
          raise UnableToWrite, e.message
        end
      end
    end
  end
end
