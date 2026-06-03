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
# -M DT  # additional meta data to generate: T = NMEA timestamp, D = decoder related \
# -gr TUNER 38.6 RTLAGC off  # Dongle gain \
# -s 2304k  # Sample rate \
# -p 0  # Dongle temperature correction, ppm \

# Console verbosity is env-tunable and quiet by default so the container doesn't flood pod logs
# (the SDR Pi keeps /var/log/pods on a small tmpfs). The web UI (-N), GEOJSON/REALTIME and hub
# feeds (-u) are separate outputs and are unaffected by -o.
#   AIS_OUTPUT_MODE      -o mode: 0=quiet (default), 1=NMEA, 2=NMEA+, 3=JSON NMEA, 4=JSON sparse, 5=JSON full
#   AIS_VERBOSE_INTERVAL if set (seconds), adds `-v <n>` periodic stats; unset (default) = no verbose
OUTPUT_MODE="${AIS_OUTPUT_MODE:-0}"
VERBOSE_ARG=""
if [ -n "$AIS_VERBOSE_INTERVAL" ]; then
    VERBOSE_ARG="-v $AIS_VERBOSE_INTERVAL"
fi

COMMAND="AIS-catcher \
    $VERBOSE_ARG \
    -M DT \
    -gr TUNER 38.6 RTLAGC off BIASTEE $BIASTEE \
    -s 2304k \
    -p 0 \
    -o $OUTPUT_MODE \
    -N $AIS_CATCHER_PORT GEOJSON on STATION \"$STATION_NAME\" STATION_LINK $STATION_URL LAT $LAT LON $LON SHARE_LOC on \
    -N PLUGIN_DIR /usr/share/aiscatcher/my-plugins \
    -N REALTIME on \
    -d $DEVICE_INDEX \
    $EXTRA_ARGS"

echo "Executing: $COMMAND"
eval $COMMAND