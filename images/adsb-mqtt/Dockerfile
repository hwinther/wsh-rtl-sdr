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

FROM cgr.dev/chainguard/python:latest-dev@sha256:c0553ee682a37a13dc2710716bc1a041d374cd4474379ca1a101044adcdabffe AS deps
# The -dev image runs as nonroot (65532); root is only needed to write /opt/deps.
USER root
COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir --no-deps --target /opt/deps -r /tmp/requirements.txt

FROM cgr.dev/chainguard/python:latest@sha256:0ce856292cb65f45ee233c5ef7fcf55bd5210102af01a08efb392c3495195909
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
