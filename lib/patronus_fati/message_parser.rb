module PatronusFati
  module MessageParser
    # We receive some messages before we specifically request the abilities of
    # the server, when this happens we'll attempt to map the data using the
    # default attribute ordering that was provided by the Kismet server this
    # client was coded against, this may not be entirely accurate, but will
    # become accurate before we receive any meaningful data.
    def self.parse(msg)
      return unless (raw_data = handle_msg(msg))

      unless (cap = get_model(raw_data[0]))
        PatronusFati.logger.warn('Message received had unknown message type: ' + raw_data[0])
        return
      end

      src_keys = cap.enabled_keys.empty? ? cap.attribute_keys : cap.enabled_keys
      cap.new(Hash[src_keys.zip(raw_data[1])])
    rescue ParseError => e
      # Detected corrupt messages from kismet in the wild, warn about them but
      # don't fail the connection.
      $stderr.puts("Warning: Unable to parse message from kismet: #{e.message}")
    end

    protected

    def self.extract_data(data_line)
      data_line.scan(PatronusFati::DATA_DELIMITER).map { |a, b| (a || b).tr("\x01", '') }
    end

    def self.extract_ssid_data(data_line)
      data_scanner = StringScanner.new(data_line.force_encoding(Encoding::BINARY))

      # We can use our normal scanner for the first 11 fields, the remainder
      # are the WPS specific fields which are just bad...
      results =  11.times.map do
        field = data_scanner.scan(PatronusFati::DATA_DELIMITER).tr("\x01", '')
        data_scanner.skip(/\s/)
        field
      end

      # We need to grab the WPS state as a byte
      results << data_scanner.get_byte
      data_scanner.skip(/\s/)

      # Put everything else in the 'wps_info' field
      results << data_scanner.rest.strip

      results
    end

    def self.get_model(mdl)
      return unless PatronusFati::MessageModels.const_defined?(model_name(mdl))
      PatronusFati::MessageModels.const_get(model_name(mdl))
    end

    def self.handle_msg(line)
      resp = PatronusFati::SERVER_MESSAGE.match(line)
      return unless resp

      h = Hash[resp.names.zip(resp.captures)]
      if h['header'] == 'SSID'
        [h['header'], extract_ssid_data(h['data'])]
      else
        [h['header'], extract_data(h['data'])]
      end
    end

    def self.model_name(hdr)
      hdr.downcase.capitalize.to_sym
    end
  end
end
