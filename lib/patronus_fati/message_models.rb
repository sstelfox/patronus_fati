require 'patronus_fati/message_models/ack'
require 'patronus_fati/message_models/alert'
require 'patronus_fati/message_models/battery'
require 'patronus_fati/message_models/bssid'
require 'patronus_fati/message_models/bssidsrc'
require 'patronus_fati/message_models/btscandev'
require 'patronus_fati/message_models/capability'
require 'patronus_fati/message_models/channel'
require 'patronus_fati/message_models/client'
require 'patronus_fati/message_models/clisrc'
require 'patronus_fati/message_models/clitag'
require 'patronus_fati/message_models/common'
require 'patronus_fati/message_models/critfail'
require 'patronus_fati/message_models/error'
require 'patronus_fati/message_models/gps'
require 'patronus_fati/message_models/info'
require 'patronus_fati/message_models/kismet'
require 'patronus_fati/message_models/nettag'
require 'patronus_fati/message_models/packet'
require 'patronus_fati/message_models/plugin'
require 'patronus_fati/message_models/protocols'
require 'patronus_fati/message_models/remove'
require 'patronus_fati/message_models/source'
require 'patronus_fati/message_models/spectrum'
require 'patronus_fati/message_models/ssid'
require 'patronus_fati/message_models/status'
require 'patronus_fati/message_models/string'
require 'patronus_fati/message_models/terminate'
require 'patronus_fati/message_models/time'
require 'patronus_fati/message_models/trackinfo'
require 'patronus_fati/message_models/wepkey'

module PatronusFati
  # @note In all of the message models the ordering of the attributes is
  #   actually important, as these are the default orderings provided by the
  #   server I was developing against.  The casing of the name is also
  #   important as the best we can automatically do from the header information
  #   is a downcase and capitalize.
  module MessageModels
  end
end
