module PatronusFati
  module MessageProcessor
    extend FactoryBase

    def self.handle(message_obj)
      factory(class_to_name(message_obj), message_obj)
    end

    def self.ignored_types
      [:ack, :battery, :channel, :gps, :info, :kismet, :plugin, :time]
    end
  end

  module InstanceHelper
    def instance_report(inst)
      puts ('New: %s' % inst.attributes) if inst.new?
      puts ('Updated (%s): %s' % [inst.changed.join(','), inst.attributes.inspect]) if inst.changed?
      puts ('Expiring: %s' % inst.attributes) if inst.expired?
      inst.flush
    end
  end
end

require 'patronus_fati/message_processor/alert'
require 'patronus_fati/message_processor/bssid'
require 'patronus_fati/message_processor/bssidsrc'
require 'patronus_fati/message_processor/capability'
require 'patronus_fati/message_processor/client'
require 'patronus_fati/message_processor/clisrc'
require 'patronus_fati/message_processor/error'
require 'patronus_fati/message_processor/protocols'
require 'patronus_fati/message_processor/source'
require 'patronus_fati/message_processor/ssid'
