There are five data models that will need to be transitioned away from SQLite.

* AccessPoint
* Client
* Connection
* Probe
* SSID

Probes can be glommed on to the Client model, and SSIDs could be added to the
AccessPoint model, but their visibility history will need to be tracked so they
may be better left as separate models.

Lookups of AccessPoint and Client will always be based on either BSSID and MAC
respectively, or time based. Time based will likely be able to efficiently be
handled with a select over the records as they will be getting periodically
cleaned up.

Connections pose a trickier problem as they need to be looked up by either of
two primary keys and I don't want to duplicate the visibility storage. I can
store the associated BSSID/MAC on the Client/AP models then use the combination
of the two to perform visibility lookups... Yeah I think that's the best
option.

It will be important to maintain the same export format for each of the models
though I can safely drop the 'additional_data' field from each. Specifically
the export formats are relevant to the access_point, client, connection, and
sync messages.

Visibility information will be stored for an hour in a bitstring for each model
with minute precision.

NOTE: I should add a warning if I detected an AP that is reported as cloaked:
false but has an empty ESSID.

## Fields Needing Populating

AccessPoint:

* BSSID -> MAC, key, required
* Channel -> integer, optional
* Max Seen Rate -> integer, optional
* Type -> string, required
* Client MACs -> array of MACs, should always be present but may be empty.
* SSIDs -> Will be an array of ESSID, should always be present but may be
  empty. Cloaked APs will have an ESSID of nil.
* Vendor -> string, optional
* Sync Status -> Enum(syncedOffline, syncedOnline, dirtyAttributes,
  dirtyChild, active, expired), metadata based on the last output status and
  whether or not it needs to be re-announced.

Client:

* MAC -> MAC, key, required
* Channel -> integer, optional
* Max Seen Rate -> integer, optional
* Access Points -> array of MACs, should always be present but may be empty.
* Probes -> Will be an array of strings, should always be present but may be
  empty
* Vendor -> string, optional
* Sync Status -> Enum(syncedOffline, syncedOnline, dirtyAttributes,
  dirtyChild, active, expired), metadata based on the last output status and
  whether or not it needs to be re-announced.

SSID:

* BSSID: BSSID of the AccessPoint that is hosting this SSID
* Beacon Rate: integer, optional
* Beacon Info: string, optional
* Cloaked: boolean
* ESSID: string, optional
* Cryptset: array of strings, should always be present, must contain at least
  one element from the SSID_CRYPT_MAP.
* Max Rate: integer, optional

AccessPointVisibility:

* Key -> ap bssid
* WindowStart -> integer, unix timestamp of beginning of visibility window
* Visbility -> bitstring / integer, required, must be > 0
* LastVisibility -> bitstring / integer, must be >= 0

I may need to add 'first seen' as a unix timestamp into this table to handle
the uptime field in the access point->offline messages. It may also not be
needed if pulse is not doing anything with it.

ClientVisibility:

* Key -> client mac
* WindowStart -> integer, unix timestamp of beginning of visibility window
* Visbility -> bitstring / integer, required, must be > 0
* LastVisibility -> bitstring / integer, must be >= 0

ConnectionVisibility:

* Key -> hash(ap bssid + client mac)
* WindowStart -> integer, unix timestamp of beginning of visibility window
* Visbility -> bitstring / integer, required, must be > 0
* LastVisibility -> bitstring / integer, must be >= 0

I may need to add 'first seen' as a unix timestamp into this table to handle
the duration field in the connection->disconnect messages. It may also not be
needed if pulse is not doing anything with it.

ProbeVisbility:

* Key -> hash(client mac + essid)
* WindowStart -> integer, unix timestamp of beginning of visibility window
* Visbility -> bitstring / integer, required, must be > 0
* LastVisibility -> bitstring / integer, must be >= 0

SsidVisibility:

* Key -> hash(ap bssid + essid)
* WindowStart -> integer, unix timestamp of beginning of visibility window
* Visbility -> bitstring / integer, required, must be > 0
* LastVisibility -> bitstring / integer, must be >= 0

## Messages for Compatibility

AccessPoint -> New

```
{"asset_type":"access_point","event_type":"new","data":{"vendor":"PEGATRON CORPORATION","bssid":"74:85:2a:6e:bb:da","channel":6,"type":"infrastructure","active":true,"connected_clients":[]},"additional_data":{},"timestamp":"2017-04-13 11:58:58 -0400"}
```

AccessPoint -> Changed

```
{"asset_type":"access_point","event_type":"changed","data":{"vendor":"PEGATRON CORPORATION","bssid":"74:85:2a:6e:bb:da","channel":6,"type":"infrastructure","active":true,"connected_clients":[],"ssids":[{"beacon_info":" ","beacon_rate":10,"cloaked":false,"crypt_set":["None"],"essid":"xfinitywifi","max_rate":216}]},"additional_data":{"ssids":[[],[{"beacon_info":" ","beacon_rate":10,"cloaked":false,"crypt_set":["None"],"essid":"xfinitywifi","max_rate":216}]]},"timestamp":"2017-04-13 11:58:58 -0400"}
```

AccessPoint -> Offline

```
{"asset_type":"access_point","event_type":"offline","data":{"bssid":"f4:f2:6d:70:fa:f0","uptime":311},"additional_data":{},"timestamp":"2017-04-13 12:06:30 -0400"}
```

I may be able to eliminate 'uptime' if Pulse isn't using it but I need to
double check it is likely still useful though...

AccessPoint -> Sync

```
{"asset_type":"access_point","event_type":"sync","data":{"vendor":"TP-LINK TECHNOLOGIES CO.,LTD.","bssid":"a4:2b:b0:dd:9c:0a","channel":10,"type":"infrastructure","active":true,"connected_clients":[],"ssids":[{"beacon_info":" ","beacon_rate":10,"cloaked":false,"crypt_set":["WPA+PSK","WPA+AES-CCM","WPA2","WPS"],"essid":"Alley Interactive 2.4g","max_rate":144}]},"additional_data":{},"timestamp":"2017-04-13 12:02:30 -0400"}
```

Client -> New

```
{"asset_type":"client","event_type":"new","data":{"vendor":"Hewlett Packard","bssid":"98:e7:f4:af:fa:6c","channel":0,"max_seen_rate":10,"active":true,"connected_access_points":[],"probes":[]},"additional_data":{},"timestamp":"2017-04-13 11:58:25 -0400"}
```

Client -> Offline

```
{"asset_type":"client","event_type":"offline","data":{"bssid":"14:30:c6:bb:7f:31","uptime":1813},"additional_data":{},"timestamp":"2017-04-13 12:54:03 -0400"}
```

Client -> Sync

```
{"asset_type":"client","event_type":"sync","data":{"vendor":"Apple, Inc.","bssid":"b4:8b:19:f3:2f:6c","channel":0,"max_seen_rate":60,"active":true,"connected_access_points":[],"probes":[]},"additional_data":{},"timestamp":"2017-04-13 12:02:30 -0400"}
```

Connection -> Connect

```
{"asset_type":"connection","event_type":"connect","data":{"access_point":"82:2a:a8:5b:5f:82","client":"28:f0:76:27:9b:68","connected":true},"additional_data":{},"timestamp":"2017-04-13 12:02:31 -0400"}
```

Connection -> Disconnect

```
{"asset_type":"connection","event_type":"disconnect","data":{"access_point":"80:2a:a8:5a:61:1e","client":"e4:ce:8f:2f:64:08","connected":false,"duration":1823},"additional_data":{},"timestamp":"2017-04-13 12:54:03 -0400"}
```

I believe I can eliminate duration from this message but need to double check

Sync -> Recent:

```
{"asset_type":"sync","event_type":"recent","data":{"access_points":["f8:7b:8c:5c:67:a2","80:2a:a8:5a:5f:95","82:2a:a8:5b:5f:95","82:2a:a8:5b:61:ab","82:2a:a8:5b:5f:82","82:2a:a8:5b:60:c7","20:c9:d0:1a:ad:ea","82:2a:a8:98:2b:47","a4:2b:b0:dd:9c:09","46:d9:e7:fb:6c:c9","56:d9:e7:fb:6c:c9","f8:7b:8c:5c:67:a3","74:85:2a:6e:a6:32","82:2a:a8:5b:61:1e","82:2a:a8:5b:63:e1","60:33:4b:e3:d8:1c","74:85:2a:6e:a6:30","80:2a:a8:41:3f:20","44:d9:e7:fa:6c:c9","80:2a:a8:5a:63:e1","46:d9:e7:fa:6c:c9","80:2a:a8:5a:5f:82","20:c9:d0:1a:ad:e9","74:85:2a:6e:a6:28","80:2a:a8:5a:61:ab","80:2a:a8:5a:60:c7","80:2a:a8:5a:5f:81","80:2a:a8:97:2b:47","60:e3:27:f2:3c:ff","80:2a:a8:5a:61:1e","74:85:2a:6e:a6:31","60:33:4b:e3:d8:1b","04:a1:51:5c:f1:07","98:e7:f4:af:fa:6d","80:2a:a8:5a:5f:42","9a:dc:96:38:a4:35","f0:9f:c2:24:de:5b","00:18:0a:34:f5:ba","74:85:2a:6e:a6:2b","10:da:43:d1:85:94","d8:9d:67:e4:02:7c","74:85:2a:6e:a6:2a","50:65:f3:04:5a:05","20:25:64:60:a4:da","f2:9f:c2:24:de:5b","88:dc:96:38:a4:35","a4:2b:b0:dd:9c:0a"],"clients":["f4:5c:89:99:10:69","f4:5c:89:cb:af:a5","f8:a9:d0:0d:63:7d","e0:9d:31:0c:78:90","00:18:0a:34:f5:ba","80:d2:1d:28:e3:d8","78:31:c1:cf:79:c4","ac:bc:32:bf:0a:09","18:cf:5e:43:6e:4a","4c:8d:79:ee:0a:3e","98:01:a7:a0:76:71","e4:ce:8f:2f:64:08","98:5a:eb:8d:8c:58","68:db:ca:c9:d1:4c","44:85:00:6e:40:d3","7c:04:d0:cb:25:bc","14:10:9f:db:95:59","c8:69:cd:b9:cc:30","28:f0:76:27:9b:68","64:bc:0c:47:97:e7","6c:76:60:3c:19:50","98:e7:f4:af:fa:6c","1c:99:4c:ad:44:9b","34:02:86:0f:13:c4","b8:76:3f:0d:86:ff","30:8c:fb:da:48:66","60:03:08:94:95:36","88:63:df:90:1a:c9","00:80:92:be:22:27","68:a8:6d:4d:53:98","ac:bc:32:a2:1c:31","94:65:9c:2f:2b:c3","f4:09:d8:db:c9:b8","b8:e8:56:45:18:a6","00:26:08:e5:24:d3","b8:8d:12:05:c9:f4","28:cf:e9:54:ed:f5","a8:5b:78:3a:6b:9d","64:b0:a6:b1:27:dd","b4:8b:19:e1:9c:00","16:26:ad:b0:c0:6f"]},"additional_data":{},"timestamp":"2017-04-13 13:10:02 -0400"}
```

Both -> Sync:

```
{"asset_type":"both","event_type":"sync","data":{"access_points":["80:2a:a8:5a:61:ab","80:2a:a8:97:2b:47","10:da:43:d1:85:94","80:2a:a8:41:3f:20","82:2a:a8:5b:61:ab","82:2a:a8:5b:60:c7","82:2a:a8:5b:5f:95","82:2a:a8:5b:5f:82","20:c9:d0:1a:ad:ea","82:2a:a8:98:2b:47","a4:2b:b0:dd:9c:09","46:d9:e7:fb:6c:c9","56:d9:e7:fb:6c:c9","f8:7b:8c:5c:67:a3","60:33:4b:e3:d8:1c","74:85:2a:6e:a6:30","82:2a:a8:5b:61:1e","82:2a:a8:5b:63:e1","74:85:2a:6e:a6:31","46:d9:e7:fa:6c:c9","80:2a:a8:5a:5f:82","44:d9:e7:fa:6c:c9","80:2a:a8:5a:63:e1","f8:7b:8c:5c:67:a2","80:2a:a8:5a:60:c7","74:85:2a:6e:a6:28","74:85:2a:6e:a6:32","80:2a:a8:5a:61:1e","80:2a:a8:5a:5f:81","04:a1:51:5c:f1:07","60:e3:27:f2:3c:ff","60:33:4b:e3:d8:1b","20:c9:d0:1a:ad:e9","80:2a:a8:5a:5f:95","d8:9d:67:e4:02:7c","f4:f2:6d:70:fa:f0","f0:9f:c2:24:de:5b","74:85:2a:6e:bb:db","70:5a:0f:6a:54:ad","f2:9f:c2:24:de:5b","74:85:2a:6e:bb:da","00:18:0a:34:f5:ba","a4:2b:b0:dd:9c:0a","20:25:64:60:a4:da","50:65:f3:04:5a:05","74:85:2a:6e:a6:2a"],"clients":["ac:bc:32:bf:0a:09","70:ec:e4:6a:6f:0f","4c:8d:79:ee:0a:3e","f8:a9:d0:0d:63:7d","e0:9d:31:0c:78:90","b8:76:3f:0d:86:ff","f4:31:c3:7f:d1:37","80:d2:1d:28:e3:d8","78:31:c1:cf:79:c4","e4:ce:8f:2f:64:08","12:46:92:f6:6f:68","f4:5c:89:cb:af:a5","80:e6:50:1c:f9:48","6c:76:60:3c:19:50","68:db:ca:c9:d1:4c","98:5a:eb:8d:8c:58","18:cf:5e:43:6e:4a","44:85:00:6e:40:d3","64:bc:0c:47:97:e7","e6:65:c9:39:77:b8","f4:5c:89:99:10:69","70:5a:0f:6a:54:ad","98:e7:f4:af:fa:6c","3c:77:e6:1a:a1:8b","98:01:a7:a0:76:71","bc:f5:ac:e0:65:47","00:18:0a:34:f5:ba","24:df:6a:15:4b:5d","34:02:86:0f:13:c4","00:80:92:be:22:27","14:10:9f:db:95:59","42:06:a5:c2:7c:47","34:02:86:0f:13:c5","c2:2c:da:83:24:38","d0:a6:37:67:7c:f2","28:f0:76:27:9b:68","94:39:e5:6c:c4:a1","ee:c5:10:eb:cf:37","b4:8b:19:f3:2f:6c"]},"additional_data":[],"timestamp":"2017-04-13 12:02:30 -0400"}
```
