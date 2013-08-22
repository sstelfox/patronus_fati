
module PatronusFati
  class Client
    def initialize(host = '127.0.0.1', port = 2501)
      @reader = Reader.new(TCPSocket.new(host, port), ParseFactory)
    end

    def tick
      @reader.buffer_available_data
      @reader.parse_buffer
    end
  end
end
