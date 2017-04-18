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

TODO NOTE: I should add a warning if I detected an AP that is reported as
cloaked: false but has an empty ESSID.

TODO: Something to consider: Right now when tracking a 'connection' I add the
bssid to the client, and the mac to the access point then mark the records with
the 'dirtyChildren' flag. Since connections are tracked independently, with
their own connect / disconnect messages I likely don't need to trigger a sync
of each of those models. I want to test and make sure that will work cleanly
though...

TODO: When I bring an access point, client, or SSID back online I need to reset
the first seen field in the respective instance's presence.

## Messages for Compatibility

Client -> New

```
{"asset_type":"client","event_type":"new","data":{"vendor":"Hewlett Packard","bssid":"98:e7:f4:af:fa:6c","channel":0,"max_seen_rate":10,"active":true,"connected_access_points":[],"probes":[]},"additional_data":{},"timestamp":"2017-04-13 11:58:25 -0400"}
```

Client -> Changed

I couldn't find a sample of this and it may not be a thing really... but the
data processor supports it so I'm going to treat it just like the new
message...

Connection -> Connect

```
{"asset_type":"connection","event_type":"connect","data":{"access_point":"82:2a:a8:5b:5f:82","client":"28:f0:76:27:9b:68","connected":true},"additional_data":{},"timestamp":"2017-04-13 12:02:31 -0400"}
```
