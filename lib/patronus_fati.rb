STDOUT.sync = true

require 'date'
require 'digest'
require 'json'
require 'openssl'
require 'socket'
require 'timeout'
require 'thread'

require 'dm-constraints'
require 'dm-core'
require 'dm-migrations'
require 'dm-observer'
require 'dm-timestamps'
require 'dm-validations'

require 'louis'

require 'patronus_fati/consts'
require 'patronus_fati/version'

require 'patronus_fati/data_mapper/crypt_flags'
require 'patronus_fati/data_mapper/null_table_prefix'

require 'patronus_fati/cap_struct'
require 'patronus_fati/connection'
require 'patronus_fati/event_handler'
require 'patronus_fati/factory_base'
require 'patronus_fati/message_models'
require 'patronus_fati/message_parser'
require 'patronus_fati/message_processor'

require 'patronus_fati/data_models/common'

require 'patronus_fati/data_models/access_point'
require 'patronus_fati/data_models/client'
require 'patronus_fati/data_models/connection'
require 'patronus_fati/data_models/mac'
require 'patronus_fati/data_models/probe'
require 'patronus_fati/data_models/ssid'

require 'patronus_fati/data_observers/access_point_observer'
require 'patronus_fati/data_observers/client_observer'
require 'patronus_fati/data_observers/connection_observer'
require 'patronus_fati/data_observers/ssid_observer'

module PatronusFati
  def self.event_handler
    @event_handler ||= PatronusFati::EventHandler.new
  end

  def self.setup(kismet_server, kismet_port, database_uri)
    #DataMapper::Logger.new('pf-db.log', :debug)
    DataMapper.setup(:default, database_uri)
    DataMapper.repository(:default).adapter.resource_naming_convention = PatronusFati::NullTablePrefix
    DataMapper.finalize
    DataMapper.auto_upgrade!

    PatronusFati::Connection.new(kismet_server, kismet_port)
  end
end
