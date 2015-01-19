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
    (1 << 6) => 'WPA', # Appears deprecated but still in the kismet source
    (1 << 7) => 'WPA+PSK',
    (1 << 8) => 'WPA+AES-OCB',
    (1 << 9) => 'WPA+AES-CCM',
    (1 << 10) => 'WPA Migration Mode',
    (1 << 11) => 'WPA+EAP', # Not a value that shows up in kismet exports... Bonus?
    (1 << 12) => 'WPA+LEAP',
    (1 << 13) => 'WPA+TTLS',
    (1 << 14) => 'WPA+TLS',
    (1 << 15) => 'WPA+PEAP',
    (1 << 20) => 'ISAKMP',
    (1 << 21) => 'PPTP',
    (1 << 22) => 'Fortress',
    (1 << 23) => 'Keyguard',
    (1 << 24) => 'Unknown Protected',
    (1 << 25) => 'Unknown Non-WEP',
    (1 << 26) => 'WPS'
  }

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
end
