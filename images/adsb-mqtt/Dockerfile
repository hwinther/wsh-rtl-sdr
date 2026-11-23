# syntax=docker/dockerfile:1
#
# adsb-mqtt: polls readsb's aircraft.json and republishes it to MQTT (mosquitto).
#
# Chainguard's Wolfi-based python (no shell or package manager, uid 65532), rebuilt daily on the
# current upstream CPython. Distroless python scanned as Debian's older python3.13 plus krb5, expat
# and libgomp: 4 critical and ~50 high, all "won't fix". paho-mqtt is pip-installed in the matching
# latest-dev builder into /opt/deps. Dependabot bumps the two digests together (base-images group)
# and requirements.txt (pip); either change rebuilds the image on merge. The free tier only publishes
# `latest`, so the Python minor can move with a digest bump; paho-mqtt is pure Python.

FROM cgr.dev/chainguard/python:latest-dev@sha256:e2736acdf97f2b1cb59545f4f26317b18a953e90e59fa4c212a782315b248111 AS deps
# The -dev image runs as nonroot (65532); root is only needed to write /opt/deps.
USER root
COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir --no-deps --target /opt/deps -r /tmp/requirements.txt

FROM cgr.dev/chainguard/python:latest@sha256:f33049a06b10d6bd729e08a181094774ca5e9c7b0cf1bbe674aa977cd5258daa
LABEL maintainer="Hans Christian Winther-Sørensen <docker@wsh.no>"
COPY --from=deps /opt/deps /opt/deps
COPY adsb-mqtt.py /srv/adsb-mqtt.py

# Defaults — override via env / k8s ConfigMap + Secret. MQTT_HOST empty = disabled (exits cleanly).
# MQTT_PASSWORD is intentionally NOT set here; it comes from a Secret at runtime.
ENV PYTHONPATH="/opt/deps" \
    PYTHONDONTWRITEBYTECODE="1" \
    MQTT_HOST="" \
    MQTT_PORT="1883" \
    MQTT_USERNAME="" \
    MQTT_TOPIC="adsb/aircraft" \
    MQTT_QOS="0" \
    MQTT_RETAIN="false" \
    MQTT_CLIENT_ID="adsb-mqtt" \
    AIRCRAFT_JSON="/data/aircraft.json" \
    POLL_INTERVAL="1" \
    PUBLISH_UNCHANGED="false"

USER 65532:65532
ENTRYPOINT ["/usr/bin/python3", "/srv/adsb-mqtt.py"]
