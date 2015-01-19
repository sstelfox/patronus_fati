module PatronusFati
  module MessageParser
    # We receive some messages before we specifically request the abilities of
    # the server, when this happens we'll attempt to map the data using the
    # default attribute ordering that was provided by the Kismet server this
    # client was coded against, this may not be entirely accurate, but will
    # become accurate before we receive any meaningful data.
    def self.parse(msg)
      raw_data = handle_msg(msg)

      unless model_exists?(raw_data['header'])
        return PatronusFati::NullObject.new
      end

      unless (cap = get_model(raw_data['header']))
        fail(ArgumentError, 'Message received had unknown message type: ' + h['header'])
      end

      src_keys = cap.enabled_keys.empty? ? cap.attribute_keys : cap.enabled_keys
      cap.new(Hash[src_keys.zip(raw_data['data'])])
    end

    protected

    def self.extract_data(data_line)
      data_line.scan(PatronusFati::DATA_DELIMITER).map { |a, b| (a || b).tr("\x01", '') }
    end

    def self.get_model(mdl)
      PatronusFati::MessageModels.const_get(mdl.downcase.capitalize.to_sym)
    end

    def self.handle_msg(line)
      resp = PatronusFati::SERVER_MESSAGE.match(line)

      h = Hash[resp.names.zip(resp.captures)]
      h['data'] = extract_data(h['data'])

      h
    end

    def self.model_exists?(hdr)
      PatronusFati::MessageModels.const_defined?(hdr.downcase.capitalize.to_sym)
    end
  end
end
