# adsb-mqtt: polls dump1090-fa's aircraft.json and republishes it to MQTT (mosquitto).
#
# Built on sdr-base (digest-pinned so Dependabot tracks the bump) for supply-chain consistency with
# the other feeders — it carries the same reusable-workflow attestations, so the cluster's cosign /
# SLSA policies admit it without a skip. It needs no SDR runtime itself, just python3 + paho-mqtt.
FROM ghcr.io/hwinther/wsh-rtl-sdr/sdr-base:trixie@sha256:3096b01a06cdef7c2712f953baba7cc1319f9912a0f3aad9f4589cc918a634e0 AS runtime
LABEL maintainer="Hans Christian Winther-Sørensen <docker@wsh.no>"
ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-x", "-o", "pipefail", "-c"]

RUN apt-get update && \
    apt-get install -y --no-install-recommends python3 python3-paho-mqtt && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY --chmod=755 adsb-mqtt.py /srv/adsb-mqtt.py

# Defaults — override via env / k8s ConfigMap + Secret. MQTT_HOST empty = disabled (exits cleanly).
# MQTT_PASSWORD is intentionally NOT set here; it comes from a Secret at runtime.
ENV MQTT_HOST="" \
    MQTT_PORT="1883" \
    MQTT_USERNAME="" \
    MQTT_TOPIC="adsb/aircraft" \
    MQTT_QOS="0" \
    MQTT_RETAIN="false" \
    MQTT_CLIENT_ID="adsb-mqtt" \
    AIRCRAFT_JSON="/data/aircraft.json" \
    POLL_INTERVAL="1" \
    PUBLISH_UNCHANGED="false"

ENTRYPOINT ["python3", "/srv/adsb-mqtt.py"]
