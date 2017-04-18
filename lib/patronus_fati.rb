require 'date'
require 'digest'
require 'json'
require 'logger'
require 'openssl'
require 'socket'
require 'strscan'
require 'timeout'
require 'thread'

require 'louis'

require 'patronus_fati/consts'
require 'patronus_fati/version'

require 'patronus_fati/cap_struct'
require 'patronus_fati/connection'
require 'patronus_fati/event_handler'
require 'patronus_fati/factory_base'
require 'patronus_fati/message_models'
require 'patronus_fati/message_parser'
require 'patronus_fati/message_processor'

require 'patronus_fati/data_models/common_state'

require 'patronus_fati/data_models/access_point'
require 'patronus_fati/data_models/client'
require 'patronus_fati/data_models/connection'
require 'patronus_fati/data_models/ssid'

require 'patronus_fati/presence'

module PatronusFati
  @@startup_time = Time.now.to_i

  def self.event_handler
    @event_handler ||= PatronusFati::EventHandler.new
  end

  def self.setup(kismet_server, kismet_port)
    PatronusFati::Connection.new(kismet_server, kismet_port)
  end

  def self.logger
    @@logger ||= Logger.new(STDOUT)
  end

  def self.logger=(logger)
    @@logger = logger
  end

  def self.startup_time
    @@startup_time
  end

  def self.past_initial_flood?
    @@flood_status ||= false
  end

  def self.past_initial_flood!
    @@flood_status = true
  end
end
