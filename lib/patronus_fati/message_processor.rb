module PatronusFati
  module MessageProcessor
    extend FactoryBase

    def self.cleanup_models
      @last_cleanup ||= Time.now.to_i
      @last_active_objects ||= {access_points: [], clients: []}

      if @last_cleanup < (Time.now.to_i - 60)
        @last_cleanup = Time.now.to_i

        offline_aps = PatronusFati::DataModels::AccessPoint.inactive.all(:id.not => @last_active_objects[:access_points])
        offline_clients = PatronusFati::DataModels::Client.inactive.all(:id.not => @last_active_objects[:clients])

        @last_active_objects = {
          access_points: PatronusFati::DataModels::AccessPoint.active.map(&:id),
          clients: PatronusFati::DataModels::Client.active.map(&:id)
        }

        offline_aps.each { |ap| puts ('AP Offline: %s' % ap.full_state.inspect) }
        offline_clients.each { |cli| puts ('Client Offline: %s' % cli.full_state.inspect) }
      end
    end

    def self.handle(message_obj)
      cleanup_models
      factory(class_to_name(message_obj), message_obj)
    rescue => e
      puts 'Error processing the following message object:'
      puts message_obj.inspect
      puts '%s: %s' % [e.class, e.message]
      puts e.backtrace.join("\n")
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
