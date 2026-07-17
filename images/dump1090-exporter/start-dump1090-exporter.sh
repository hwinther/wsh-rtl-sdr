#!/bin/bash
# Wraps dump1090exporter (https://github.com/claws/dump1090-exporter).
# RESOURCE_PATH: dump1090-fa data dir (e.g. the shared /run/dump1090-fa emptyDir) or an
# http(s) URL to a dump1090 /data endpoint. LAT/LON: receiver position for max-range
# calculation; when unset the exporter falls back to receiver.json.
set -euo pipefail

ARGS=(--resource-path="$RESOURCE_PATH" --port="$EXPORTER_PORT")
if [ -n "$LAT" ]; then
    ARGS+=(--latitude="$LAT")
fi
if [ -n "$LON" ]; then
    ARGS+=(--longitude="$LON")
fi

echo "Executing: dump1090exporter ${ARGS[*]}"
exec /opt/dump1090exporter/bin/dump1090exporter "${ARGS[@]}"
