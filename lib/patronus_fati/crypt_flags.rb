module DataMapper
  class Property
    class CryptFlags < DataMapper::Property::Integer
      def custom?
        true
      end

      def dump(value)
        unless value.nil?
          flags = Array(value).map(&:to_sym).uniq
          valid_values = flags & PatronusFati::SSID_CRYPT_MAP.values.map(&:to_sym)

          PatronusFati::SSID_CRYPT_MAP.map { |k, v| valid_values.include?(v.to_sym) ? k : 0 }.inject(&:+)
        end
      end

      def load(value)
        return [] if value.nil?
        PatronusFati::SSID_CRYPT_MAP.select { |k, v| (k & value) == k }.map { |k, v| v }
      end

      def typecast(value)
        case value
          when nil     then nil
          when ::Array then value.map { |v| v.to_sym }
          else [value.to_sym]
        end
      end
    end
  end
end
