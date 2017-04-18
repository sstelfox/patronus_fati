module PatronusFati
  module MessageProcessor
    extend FactoryBase

    def self.cleanup_models
      @next_cleanup ||= Time.now.to_i + 60

      if @next_cleanup <= Time.now.to_i
        @next_cleanup = Time.now.to_i + 60

        offline_access_points
        offline_clients
        close_inactive_connections
      end
    end

    def self.close_inactive_connections
      DataModels::Connection.instances.each do |_, connection|
        if !connection.active? && (connection.sync_status == SYNC_FLAGS[:unsynced] || connection.sync_flag?(:syncedOnline))
          # Intentionally clear all other flags
          connection.sync_status = SYNC_FLAGS[:syncedOffline]

          PatronusFati.event_handler.event(
            :connection, :disconnect,
            {
              'access_point' => connection.bssid,
              'client' => connection.mac,
              'connected' => false,
              'duration' => connection.presence.visible_time
            }
          )

          DataModels::AccessPoint[connection.bssid].remove_client(connection.mac)
          DataModels::Client[connection.mac].remove_access_point(connection.bssid)
        end
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
      DataModels::Client.instances.each do |mac, client|
        if !client.active? && (client.sync_status == SYNC_FLAGS[:unsynced] || client.sync_flag?(:syncedOnline))
          # Intentionally clear all other flags
          client.sync_status = SYNC_FLAGS[:syncedOffline]

          PatronusFati.event_handler.event(
            :client, :offline, {
              'bssid' => mac,
              'uptime' => client.presence.visible_time
            }
          )

          client.access_point_bssids.each do |bssid|
            DataModels::AccessPoint[bssid].remove_client(mac)
            DataModels::Connection["#{bssid}:#{mac}"].link_lost = true
          end
        end
      end

      DataModels::Client.instances.reject! { |_, ap| ap.presence.dead? }
    end

    def self.report_recently_seen
      @next_recent_msg ||= Time.now.to_i + 240

      if @next_recent_msg <= Time.now.to_i
        @next_recent_msg = Time.now.to_i + 240
        cutoff_time = Time.now.to_i - 300

        aps = DataModels::AccessPoint.instances.map do |bssid, ap|
          next unless ap.active? && ap.presence.visible_since?(cutoff_time)
          bssid
        end.compact

        clients = DataModels::Client.instances.map do |mac, client|
          next unless client.active? && client.presence.visible_since?(cutoff_time)
          mac
        end.compact

        return if clients.empty? && aps.empty?
        PatronusFati.event_handler.event(
          :sync,
          :recent,
          { access_points: aps, clients: clients }
        )
      end
    end

    def self.handle(message_obj)
      if !PatronusFati.past_initial_flood? && @last_msg_received && (Time.now.to_f - @last_msg_received) >= 0.8
        PatronusFati.past_initial_flood!
      end
      @last_msg_received = Time.now.to_f

      periodic_flush
      report_recently_seen
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
       :plugin, :source, :status, :time]
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
          PatronusFati.event_handler.event(:access_point, :sync, access_point.full_state)
          access_points << bssid
        end

        PatronusFati::DataModels::Client.instances.each do |mac, client|
          next unless client.active?
          PatronusFati.event_handler.event(:client, :sync, client.full_state)
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
require 'patronus_fati/message_processor/ssid'
require 'patronus_fati/message_processor/terminate'
