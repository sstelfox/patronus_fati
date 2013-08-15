
require 'socket'

module PatronusFati
  class Connection
    def initialize(host, port)
      @socket = TCPSocket.new(host, port)
    end

    def poll
    end
  end
end

