#!/usr/bin/env python3
"""Publish dump1090-fa's aircraft.json to MQTT.

dump1090-fa has no native MQTT output; it writes a decoded aircraft snapshot (aircraft.json,
~1 Hz) to a directory shared with tar1090. This polls that file and republishes the raw bytes to
a single MQTT topic so downstream apps get the whole-picture-every-second feed.

Configuration is via env (see Dockerfile defaults). MQTT_HOST unset = disabled. The password comes
from MQTT_PASSWORD (a Secret in k8s) and is never baked into the image.
"""
import os
import sys
import time

import paho.mqtt.client as mqtt


def _env(name, default=None):
    return os.environ.get(name, default)


def _make_client(client_id):
    # paho-mqtt 2.x requires a CallbackAPIVersion; 1.x doesn't have the enum. Support both.
    try:
        return mqtt.Client(mqtt.CallbackAPIVersion.VERSION1, client_id=client_id)
    except AttributeError:
        return mqtt.Client(client_id=client_id)


def main():
    host = _env("MQTT_HOST")
    if not host:
        print("MQTT_HOST not set — nothing to publish, exiting.", flush=True)
        return 0

    port = int(_env("MQTT_PORT", "1883"))
    user = _env("MQTT_USERNAME") or None
    password = _env("MQTT_PASSWORD") or None
    topic = _env("MQTT_TOPIC", "adsb/aircraft")
    qos = int(_env("MQTT_QOS", "0"))
    retain = _env("MQTT_RETAIN", "false").lower() == "true"
    client_id = _env("MQTT_CLIENT_ID", "adsb-mqtt")
    path = _env("AIRCRAFT_JSON", "/data/aircraft.json")
    interval = float(_env("POLL_INTERVAL", "1"))
    publish_unchanged = _env("PUBLISH_UNCHANGED", "false").lower() == "true"

    client = _make_client(client_id)
    if user:
        client.username_pw_set(user, password)
    client.reconnect_delay_set(min_delay=1, max_delay=30)
    print(
        f"adsb-mqtt: mqtt://{user or ''}@{host}:{port} topic={topic} "
        f"src={path} interval={interval}s qos={qos} retain={retain}",
        flush=True,
    )
    # connect_async + loop_start handles (re)connection in the background; the publish loop never blocks on it.
    client.connect_async(host, port, keepalive=60)
    client.loop_start()

    last = None
    missing_logged = False
    while True:
        try:
            with open(path, "rb") as fh:
                data = fh.read()
            missing_logged = False
            if publish_unchanged or data != last:
                client.publish(topic, data, qos=qos, retain=retain)
                last = data
        except FileNotFoundError:
            if not missing_logged:
                print(f"{path} not found yet (waiting for dump1090-fa)", flush=True)
                missing_logged = True
        except Exception as exc:  # keep the loop alive on transient read/publish errors
            print(f"adsb-mqtt: error: {exc}", flush=True)
        time.sleep(interval)


if __name__ == "__main__":
    sys.exit(main())
