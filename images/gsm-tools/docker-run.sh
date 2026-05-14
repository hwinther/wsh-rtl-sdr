#!/bin/bash
sudo docker run --rm -v /dev/bus/usb:/dev/bus/usb --device-cgroup-rule='c 189:* rwm' -v $(pwd)/../gsm_scan:/srv/gsm_scan -w /srv --cap-add=NET_ADMIN --cap-add=NET_RAW --privileged -it ghcr.io/hwinther/wsh-rtl-sdr/gsm-tools:latest
