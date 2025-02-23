#!/bin/bash
docker run --rm -v /dev/bus/usb:/dev/bus/usb --device-cgroup-rule='c 189:* rwm' -v /root/wsh-rtl-sdr/gsm_scan:/srv/gsm_scan -w /srv --cap-add=NET_ADMIN --cap-add=NET_RAW -it test
