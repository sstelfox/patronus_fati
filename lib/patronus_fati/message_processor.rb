module PatronusFati
  module MessageProcessor
    extend FactoryBase

    def self.handle(message_obj)
      factory(class_to_name(message_obj), message_obj)
    end

    def self.ignored_types
      [:ack, :battery, :bssidsrc, :channel, :clisrc, :gps, :info, :kismet,
       :plugin, :source, :status, :time]
    end
  end
end

require 'patronus_fati/message_processor/alert'
require 'patronus_fati/message_processor/bssid'
require 'patronus_fati/message_processor/capability'
require 'patronus_fati/message_processor/client'
require 'patronus_fati/message_processor/critfail'
require 'patronus_fati/message_processor/error'
require 'patronus_fati/message_processor/protocols'
require 'patronus_fati/message_processor/ssid'
