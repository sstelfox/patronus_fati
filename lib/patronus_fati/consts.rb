module PatronusFati
  BSSID_TYPE_MAP = {
    0   => 'infrastructure',
    1   => 'adhoc',
    2   => 'probe',
    3   => 'turbocell',
    4   => 'data',
    255 => 'mixed',
    256 => 'remove'
  }

  # 'DS' is short for distribution system, it has something to do with packet
  # domains 'BSS' (the prefix on BSSID) but it's clear that identifier is more
  # than what I thought it was...
  CLIENT_TYPE_MAP = {
    0 => 'unknown',
    1 => 'from_ds',
    2 => 'to_ds',
    3 => 'inter_ds',
    4 => 'established',
    5 => 'adhoc',
    6 => 'remove'
  }

  DATA_DELIMITER = /(\x01[^\x01]+\x01)|(\S+)/

  # This map was retrieved from a combination of the packet_ieee80211.h header
  # file and dumpfile_netxml.cc source in the kismet git repo.
  SSID_CRYPT_MAP = {
    0 => 'None',
    1 => 'Unknown',
    (1 << 1) => 'WEP',
    (1 << 2) => 'Layer3',
    (1 << 3) => 'WEP40',
    (1 << 4) => 'WEP104',
    (1 << 5) => 'WPA+TKIP',
    (1 << 7) => 'WPA+PSK',
    (1 << 8) => 'WPA+AES-OCB',
    (1 << 9) => 'WPA+AES-CCM',
    (1 << 10) => 'WPA+LEAP',
    (1 << 11) => 'WPA+TTLS',
    (1 << 12) => 'WPA+TLS',
    (1 << 13) => 'WPA+PEAP',
    (1 << 14) => 'ISAKMP',
    (1 << 15) => 'PPTP',
    (1 << 16) => 'Fortress',
    (1 << 17) => 'Keyguard',
    (1 << 18) => 'Unknown_NonWEP',
    (1 << 19) => 'WPA Migration Mode',
    (1 << 20) => 'WPA',
    (1 << 21) => 'WPA2',
    (1 << 26) => 'WPS',
  }

  SSID_CRYPT_MAP_INVERTED = Hash[SSID_CRYPT_MAP.map { |k, v| [v, k] }]

  SSID_TYPE_MAP = {
    0 => 'beacon',
    1 => 'probe_response',
    2 => 'probe_request',
    3 => 'file'
  }

  SERVER_MESSAGE = /
    (?<header> [A-Z]+){0}
    (?<data> .+){0}

    ^\*\g<header>:\s+\g<data>$
  /x

  # Various states of synchronization an individual model can be in. The
  # various sync states should remain exclusive to each other (no more than
  # one should be set). Dirtiness is an indicator of what we need to sync.
  SYNC_FLAGS = {
    unsynced: 0,
    syncedOnline: 1,
    syncedOffline: (1 << 1),
    dirtyAttributes: (1 << 2),
    dirtyChildren: (1 << 3),
  }.freeze

  # This is how many tracked intervals do we need to see overlapping before we
  # consider an access point as transmitting multiple SSIDs. The length of this
  # is dependent on the length of presence intervals
  #
  # @see PatronusFati::WINDOW_LENGTH
  # @see PatronusFati::WINDOW_INTERVALS
  # @see PatronusFati::INTERVAL_DURATION
  SIMULTANEOUS_SSID_THRESHOLD = 2

  # Number of seconds before we consider an access point as offline
  AP_EXPIRATION = 300

  # Number of seconds before we consider a client as no longer within range.
  CLIENT_EXPIRATION = 1800

  # How long before a connection between a client and an access point is
  # consider no longer actively connected.
  CONNECTION_EXPIRATION = 1800

  # Number of seconds before we consider an access point no longer advertising
  # an SSID. It is safe for this to be longer than the AP expiration; If we
  # think the AP has gone offline we will automatically mark all SSIDs as
  # inactive.
  SSID_EXPIRATION = 600

  WPS_SETTING_MAP = {
    0 => 'NO_WPS',
    1 => 'WPS_CONFIGURED',
    (1 << 1) => 'WPS_NOT_CONFIGURED',
    (1 << 2) => 'WPS_LOCKED',
  }

  # How many seconds do each of our windows last
  WINDOW_LENGTH = 3600

  # How many intervals do we break each of our windows into? This must be
  # less than 64.
  WINDOW_INTERVALS = 60

  # How long each interval will last in seconds
  INTERVAL_DURATION = WINDOW_LENGTH / WINDOW_INTERVALS

  Error = Class.new(StandardError)
  DisconnectError = Class.new(PatronusFati::Error)
  ParseError = Class.new(PatronusFati::Error)
end
