
module PatronusFati
  class Client
    attr_reader :server_info

    def initialize(host = '127.0.0.1', port = 2501)
      @reader = Reader.new(TCPSocket.new(host, port), ParseFactory.new(self))
    end

    def tick
      @reader.buffer_available_data
      msgs = @reader.parse_buffer
    end
  end
end
