module PatronusFati
  module DataModels
    module ReportedAttributes
      def self.included(klass)
        klass.extend RAClassMethods
        klass.property  :reported_online, DataMapper::Property::Boolean,  :default  => false
      end

      module RAClassMethods
        def reported_offline
          all(:reported_online => false)
        end

        def reported_online
          all(:reported_online => true)
        end
      end
    end

    module ExpirationAttributes
      def self.included(klass)
        klass.extend EAClassMethods
        klass.property  :last_seen_at,  DataMapper::Property::Integer,  :default  => Proc.new { Time.now.to_i }
      end

      def active?
        last_seen_at < self.class.current_expiration_threshold
      end

      def seen!
        update(last_seen_at: Time.now.to_i)
      end

      def uptime
        Time.now.to_i - last_seen_at
      end

      module EAClassMethods
        def active
          all(:last_seen_at.gte => current_expiration_threshold)
        end

        def inactive
          all(:last_seen_at.lt => current_expiration_threshold)
        end
      end
    end
  end
end
