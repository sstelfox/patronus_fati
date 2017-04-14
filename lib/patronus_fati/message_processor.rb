module PatronusFati
  module MessageProcessor
    extend FactoryBase

    def self.cleanup_models
      # TODO: This functionality needs to updated to not use the database
      return
      @next_cleanup ||= Time.now.to_i + 60

      if @next_cleanup <= Time.now.to_i
        @next_cleanup = Time.now.to_i + 30

        PatronusFati::DataModels::AccessPoint.inactive.reported_online.each do |ap|
          ap.update(:reported_online => false)
          PatronusFati.event_handler.event(:access_point, :offline, {'bssid' => ap.bssid, 'uptime' => ap.uptime})
          ap.disconnect_clients!
          ap.destroy
        end

        PatronusFati::DataModels::Client.inactive.reported_online.each do |cli|
          cli.update(:reported_online => false)
          PatronusFati.event_handler.event(:client, :offline, {'bssid' => cli.bssid, 'uptime' => cli.uptime})
          cli.disconnect!
          cli.destroy
        end

        PatronusFati::DataModels::Connection.inactive.connected.map(&:disconnect!)

        # When we destroy SSIDs we need to announce the change has occurred,
        # otherwise they won't go away until the next sync message.
        PatronusFati::DataModels::Ssid.inactive.each do |ssid|
          ap = ssid.access_point
          prev_ssids = ap.ssids.active.map(&:full_state)

          ssid.destroy

          PatronusFati.event_handler.event(
            :access_point,
            :changed,
            ap.full_state,
            {
              ssids: [
                prev_ssids,
                ap.ssids.active.map(&:full_state)
              ]
            }
          )
        end
      end
    end

    def self.report_recently_seen
      # TODO: This functionality needs to updated to not use the database
      return
      # Every four minutes to ensure we hit the five minute window
      @next_recent_msg ||= Time.now.to_i + 240

      if @next_recent_msg <= Time.now.to_i
        @next_recent_msg = Time.now.to_i + 240

        aps = PatronusFati::DataModels::AccessPoint.all(
          :last_seen_at.gte => (Time.now.to_i - 300),
          :fields => [:last_seen_at, :bssid]
        ).map { |c| c.bssid }
        clients = PatronusFati::DataModels::Client.all(
          :last_seen_at.gte => (Time.now.to_i - 300),
          :fields => [:last_seen_at, :bssid]
        ).map { |c| c.bssid }

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
    rescue DataObjects::SyntaxError => e
      # SQLite dropped our database. We need to log the condition and bail out
      # of the program completely.
      PatronusFati.logger.error('SQLite dropped our database: %s: %s' % [e.class, e.message])
      PatronusFati.logger.error('Exiting since we don\'t have a database...')
      exit 1
    rescue => e
      PatronusFati.logger.error('Error processing the following message object:')
      PatronusFati.logger.error(message_obj.inspect)
      PatronusFati.logger.error('%s: %s' % [e.class, e.message])
      e.backtrace.each do |l|
        PatronusFati.logger.error(l)
      end
    end

    def self.ignored_types
      [:ack, :battery, :bssidsrc, :channel, :clisrc, :gps, :info, :kismet,
       :plugin, :source, :status, :time]
    end

    def self.periodic_flush
      # TODO: This functionality needs to updated to not use the database
      return
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
