#!/bin/bash

# https://docs.aiscatcher.org/configuration/overview/

# -d 00000162  # Dongle serial \
# -u 127.0.0.1 2233  # UDP output to AIS Dispatcher \
# -u 5.9.207.224 11661  # MarineTraffic.com \
# -u ais.vesselfinder.com 6860  # VesselFinder.com \
# -u hub.shipxplorer.com 37615  # ShipXplorer.com \
# -X 00000000-1111-2222-3333-444444444444  # ais-catcher station ID \
#-Q mqtt://127.0.0.1:1883 guest MSGFORMAT JSON_FULL TOPIC data/ais \

# -N 80  # Port number for web interface \
# -v 10  # Verbose output each x seconds \
# -M DT  # additional meta data to generate: T = NMEA timestamp, D = decoder related \
# -gr TUNER 38.6 RTLAGC off  # Dongle gain \
# -s 2304k  # Sample rate \
# -p 0  # Dongle temperature correction, ppm \
# -o 4  # Output JSON sparse to console \

COMMAND="/usr/local/bin/AIS-catcher \
    -v 10 \
    -M DT \
    -gr TUNER 38.6 RTLAGC off BIASTEE $BIASTEE \
    -s 2304k \
    -p 0 \
    -o 4 \
    -N $AIS_CATCHER_PORT GEOJSON on STATION \"$STATION_NAME\" STATION_LINK $STATION_URL LAT $LAT LON $LON SHARE_LOC on \
    -N PLUGIN_DIR /usr/share/aiscatcher/my-plugins \
    -N REALTIME on \
    -d $DEVICE_INDEX \
    $EXTRA_ARGS"

echo "Executing: $COMMAND"
eval $COMMAND