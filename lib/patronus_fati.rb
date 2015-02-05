require 'digest'
require 'openssl'
require 'socket'
require 'timeout'
require 'thread'

require 'dm-constraints'
require 'dm-core'
require 'dm-migrations'
require 'dm-observer'
require 'dm-sqlite-adapter'
require 'dm-timestamps'
require 'dm-validations'

require 'patronus_fati/consts'
require 'patronus_fati/version'

require 'patronus_fati/cap_struct'
require 'patronus_fati/connection'
require 'patronus_fati/factory_base'
require 'patronus_fati/message_models'
require 'patronus_fati/message_parser'
require 'patronus_fati/message_processor'

require 'patronus_fati/data_models/access_point'
require 'patronus_fati/data_models/alert'
require 'patronus_fati/data_models/broadcast'
require 'patronus_fati/data_models/client'
require 'patronus_fati/data_models/connection'
require 'patronus_fati/data_models/mac'
require 'patronus_fati/data_models/probe'
require 'patronus_fati/data_models/ssid'

require 'patronus_fati/data_observers/access_point_observer'
require 'patronus_fati/data_observers/client_observer'
require 'patronus_fati/data_observers/ssid_observer'

module DataMapper
  class Query
    alias :original_append_condition :append_condition

    # This needs to be overridden to add support for dynamic timestamp queries
    # by using a Proc (no arguments are provided to the Proc).
    def append_condition(subject, bind_value, model = self.model, operator = :eql)
      bind_value = bind_value.call if bind_value.is_a?(Proc)
      original_append_condition(subject, bind_value, model, operator)
    end
  end
end

module PatronusFati
end
