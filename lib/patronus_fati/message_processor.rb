module PatronusFati
  module MessageProcessor
    extend FactoryBase

    def self.handle(message_obj)
      factory(class_to_name(message_obj), message_obj)
    end

    def self.ignored_types
      [:ack, :battery, :channel, :gps, :info, :kismet, :plugin, :status, :time]
    end
  end

  module InstanceHelper
    def instance_report(inst)
      type = inst.class.to_s.split('::').last

      puts ('New %s:%s: %s' % [type, inst.id_key, inst.attributes]) if inst.new?
      puts ('Updated %s:%s (%s): %s' % [type, inst.id_key, inst.changed.join(','), inst.attributes.inspect]) if inst.changed?

      if inst.expired?
        inst.class.remove_instance(inst)
        puts ('Expiring %s:%s: %s' % [type, inst.id_key, inst.attributes])
      end

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
