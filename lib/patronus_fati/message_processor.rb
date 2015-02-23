module PatronusFati
  module MessageProcessor
    extend FactoryBase

    def self.cleanup_models
      @last_cleanup ||= Time.now.to_i

      if @last_cleanup < (Time.now.to_i - 10)
        @last_cleanup = Time.now.to_i

        PatronusFati::DataModels::AccessPoint.inactive.reported_active.each do |ap|
          ap.update(:reported_status => 'expired')
          puts JSON.generate({'record_type' => 'access_point', 'report_type' => 'offline', 'data' => {'bssid' => ap.bssid}})
          ap.disconnect_clients!
        end

        PatronusFati::DataModels::Client.inactive.reported_active.each do |cli|
          cli.update(:reported_status => 'expired')
          puts JSON.generate({'record_type' => 'client', 'report_type' => 'offline', 'data' => {'bssid' => cli.bssid}})
          cli.disconnect!
        end

        PatronusFati::DataModels::Connection.expired.map(&:destroy)
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
