module PatronusFati
  module MessageProcessor
    extend FactoryBase

    def self.cleanup_models
      @next_cleanup ||= Time.now.to_i + 60

      if @next_cleanup <= Time.now.to_i
        @next_cleanup = Time.now.to_i + 10

        PatronusFati::DataModels::AccessPoint.inactive.reported_online.each do |ap|
          ap.update(:reported_online => false)
          PatronusFati.event_handler.event(:access_point, :offline, {'bssid' => ap.bssid, 'uptime' => ap.uptime})
          ap.disconnect_clients!
        end

        PatronusFati::DataModels::Client.inactive.reported_online.each do |cli|
          cli.update(:reported_online => false)
          PatronusFati.event_handler.event(:client, :offline, {'bssid' => cli.bssid, 'uptime' => cli.uptime})
          cli.disconnect!
        end

        PatronusFati::DataModels::Connection.inactive.connected.map(&:disconnect!)
      end
    end

    def self.handle(message_obj)
      periodic_flush
      result = factory(class_to_name(message_obj), message_obj)
      cleanup_models
      result
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

    def self.periodic_flush
      @next_sync ||= Time.now.to_i + 300

      if @next_sync <= Time.now.to_i
        # Add a variability of +/- half an hour within a day
        @next_sync = Time.now.to_i + 84600 + rand(3600)

        PatronusFati::DataModels::AccessPoint.active.each do |ap|
          PatronusFati.event_handler.event(:access_point, :sync, ap.full_state, {})
        end

        PatronusFati::DataModels::Client.active.each do |cli|
          PatronusFati.event_handler.event(:client, :sync, cli.full_state, {})
        end

        all_online = {
          access_points: PatronusFati::DataModels::AccessPoint.active.all(fields: [:bssid]).map(&:bssid),
          clients: PatronusFati::DataModels::Client.active.all(fields: [:bssid]).map(&:bssid)
        }
        PatronusFati.event_handler.event(:both, :sync, all_online, [])
      end
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
require 'patronus_fati/message_processor/terminate'
