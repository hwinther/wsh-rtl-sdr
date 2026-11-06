# syntax=docker/dockerfile:1
#
# adsb-mqtt: polls readsb's aircraft.json and republishes it to MQTT (mosquitto).
#
# Distroless python (Debian 13's python3.13, no shell, uid 65532). paho-mqtt is pip-installed in a
# trixie builder with the same Python into /opt/deps. Dependabot bumps the two digests (docker) and
# requirements.txt (pip); either change rebuilds the image on merge.

FROM debian:trixie-slim@sha256:a72b4433de1cf7d6bae0c4cee74d0547f58601a643b3375f070c51600d63b6b2 AS deps
RUN apt-get update &&     apt-get install -y --no-install-recommends python3-pip &&     rm -rf /var/lib/apt/lists/*
COPY requirements.txt /tmp/requirements.txt
RUN pip3 install --no-cache-dir --break-system-packages --no-deps --target /opt/deps -r /tmp/requirements.txt

FROM gcr.io/distroless/python3-debian13:nonroot@sha256:1c32c3720dc4c7f0c7dbe998737f32c200add6511eca7cec705008be488b87d6
LABEL maintainer="Hans Christian Winther-Sørensen <docker@wsh.no>"
COPY --from=deps /opt/deps /opt/deps
COPY adsb-mqtt.py /srv/adsb-mqtt.py

# Defaults — override via env / k8s ConfigMap + Secret. MQTT_HOST empty = disabled (exits cleanly).
# MQTT_PASSWORD is intentionally NOT set here; it comes from a Secret at runtime.
ENV PYTHONPATH="/opt/deps"     PYTHONDONTWRITEBYTECODE="1"     MQTT_HOST=""     MQTT_PORT="1883"     MQTT_USERNAME=""     MQTT_TOPIC="adsb/aircraft"     MQTT_QOS="0"     MQTT_RETAIN="false"     MQTT_CLIENT_ID="adsb-mqtt"     AIRCRAFT_JSON="/data/aircraft.json"     POLL_INTERVAL="1"     PUBLISH_UNCHANGED="false"

ENTRYPOINT ["/usr/bin/python3", "/srv/adsb-mqtt.py"]
