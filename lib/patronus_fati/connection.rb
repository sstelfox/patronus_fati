module PatronusFati
  class Connection
    attr_reader :port, :read_queue, :server, :write_queue

    def initialize(server, port)
      @server = server
      @port = port

      self.read_queue = Queue.new
      self.write_queue = Queue.new
    end

    def connect
      establish_connection
      return unless connected?

      start_read_thread
      start_write_thread
    end

    def connected?
      !(socket.nil? || socket.closed?)
    end

    def disconnect
      return unless socket

      Thread.kill(read_thread)
      Thread.kill(write_thread)

      socket.close unless socket.closed?

      self.socket = nil
    end

    def read
      read_queue.pop
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
        rescue IOError, EOFError => e
          raise DisconnectError
        rescue => e
          PatronusFati.logger.error(format('Error in read thread: %s %s', e.class.to_s, e.message))
          e.backtrace.each do |l|
            PatronusFati.logger.error(l)
          end
        ensure
          socket.close if socket && !socket.closed?
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
          PatronusFati.logger.error(format('Error in write thread: %s %s', e.class.to_s, e.message))
          e.backtrace.each do |l|
            PatronusFati.logger.error(l)
          end
        ensure
          socket.close if socket && !socket.closed?
        end
      end
    end
  end
end
