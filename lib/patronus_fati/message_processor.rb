module PatronusFati
  module MessageProcessor
    extend FactoryBase

    def self.cleanup_models
      @next_cleanup ||= Time.now.to_i + 60

      if @next_cleanup <= Time.now.to_i
        @next_cleanup = Time.now.to_i + 60

        close_inactive_connections

        offline_access_points
        offline_clients
      end
    end

    def self.close_inactive_connections
      DataModels::Connection.instances.each do |_, connection|
        connection.announce_changes
      end

      DataModels::Connection.instances.reject! { |_, conn| conn.presence.dead? }
    end

    def self.offline_access_points
      DataModels::AccessPoint.instances.each do |bssid, access_point|
        access_point.cleanup_ssids
        access_point.announce_changes
      end

      DataModels::AccessPoint.instances.reject! { |_, ap| ap.presence.dead? }
    end

    def self.offline_clients
      DataModels::Client.instances.each do |_, client|
        client.cleanup_probes
        client.announce_changes
      end

      DataModels::Client.instances.reject! { |_, ap| ap.presence.dead? }
    end

    def self.handle(message_obj)
      if !PatronusFati.past_initial_flood? && @last_msg_received && (Time.now.to_f - @last_msg_received) >= 0.8
        PatronusFati.past_initial_flood!
      end
      @last_msg_received = Time.now.to_f

      periodic_flush
      result = factory(class_to_name(message_obj), message_obj)
      cleanup_models
      result
    rescue => e
      PatronusFati.logger.error('Error processing the following message object:')
      PatronusFati.logger.error(message_obj.inspect)
      PatronusFati.logger.error('%s: %s' % [e.class, e.message])
      e.backtrace.each do |l|
        PatronusFati.logger.error(l)
      end

      # Need to ensure our backtrace doesn't get sent to kismet
      nil
    end

    def self.ignored_types
      [:ack, :battery, :bssidsrc, :channel, :clisrc, :gps, :info, :kismet,
       :plugin, :status, :time]
    end

    def self.periodic_flush
      @next_sync ||= Time.now.to_i + 300

      if @next_sync <= Time.now.to_i
        # Add a variability of +/- half an hour within a day
        @next_sync = Time.now.to_i + 84600 + rand(3600)

        access_points = []
        clients = []

        PatronusFati::DataModels::AccessPoint.instances.each do |bssid, access_point|
          next unless access_point.active?
          PatronusFati.event_handler.event(:access_point, :sync, access_point.full_state, access_point.diagnostic_data)
          access_points << bssid
        end

        PatronusFati::DataModels::Client.instances.each do |mac, client|
          next unless client.active?
          PatronusFati.event_handler.event(:client, :sync, client.full_state, client.diagnostic_data)
          clients << mac
        end

        all_online = { access_points: access_points, clients: clients }
        PatronusFati.event_handler.event(:both, :sync, all_online)
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
require 'patronus_fati/message_processor/source'
require 'patronus_fati/message_processor/ssid'
require 'patronus_fati/message_processor/terminate'
