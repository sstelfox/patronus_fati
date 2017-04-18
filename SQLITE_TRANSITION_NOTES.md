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

TODO: I need to have a validity check on each of the models before validating
them...
