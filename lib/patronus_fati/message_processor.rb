module PatronusFati
  module MessageProcessor
    extend FactoryBase

    def self.handle(message_obj)
      factory(class_to_name(message_obj), message_obj)
    end

    def self.ignored_types
      [:ack, :battery, :channel, :gpsd, :info, :time]
    end
  end
end

require 'patronus_fati/message_processor/capability'
require 'patronus_fati/message_processor/protocols'
require 'patronus_fati/message_processor/source'
