# syntax=docker/dockerfile:1
#
# sdr-toolbox: an interactive debugging and experimentation image for the edge SDR dongles. It
# idles (sleep) so you can `kubectl exec` into it, and holds a dongle through the device plugin
# (sdr.wsh.no/*) instead of privileged/hostPath, so the matching decoder has to release it first.
#
#   rtl-sdr        rtl_test, rtl_sdr, rtl_tcp, rtl_power, rtl_fm, rtl_eeprom
#   rtl-433        433/868/915 MHz ISM decoder (weather stations, sensors, remotes, TPMS)
#   multimon-ng    POCSAG/FLEX pagers, DTMF, AFSK, EAS
#   hackrf, airspy, soapysdr-tools (+ rtlsdr/hackrf/airspy modules) for other dongles
#   readsb, AIS-catcher  the static binaries from this repo's own images, for ad-hoc decoder tests
#   sox, socat, netcat, curl, jq, python3 + numpy, usbutils, iproute2, procps, dig
#
# debian:trixie-slim, uid 65532 (the device plugin's containerd drop-in gives the device to the
# pod's uid/gid). A developer tool: the Grype gate reports findings without failing the build.
#
# Updates: Dependabot bumps the debian, readsb and ais-catcher digests.

FROM ghcr.io/hwinther/wsh-rtl-sdr/readsb:0.19.2@sha256:480bb4ee204dd1a0dffe884cbbf4e6c53e537ea16737f27add583095f1a028ba AS readsb
FROM ghcr.io/hwinther/wsh-rtl-sdr/ais-catcher:0.19.2@sha256:1100c6c46f2b859ae54cb5f5c8900516714bd875cc8a80c8d20510acde54696b AS ais-catcher

FROM debian:trixie-slim@sha256:a72b4433de1cf7d6bae0c4cee74d0547f58601a643b3375f070c51600d63b6b2
LABEL maintainer="Hans Christian Winther-Sørensen <docker@wsh.no>"
# TODO: drop the zlib1g pin once Dependabot moves debian:trixie-slim to a digest that ships
# 1:1.3.dfsg+really1.3.1-1+deb13u1 (CVE-2026-76844, CVE-2026-85091). The newest digest still had the
# vulnerable -1+b1, and the release's Grype gate fails on a high finding that has a fix. Pinned to the
# exact version rather than `apt-get upgrade`, so the build stays defined by this file.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        zlib1g=1:1.3.dfsg+really1.3.1-1+deb13u1 \
        rtl-sdr rtl-433 multimon-ng \
        hackrf airspy soapysdr-tools soapysdr-module-rtlsdr soapysdr-module-hackrf soapysdr-module-airspy \
        sox socat netcat-openbsd curl ca-certificates jq python3 python3-numpy \
        usbutils iproute2 procps less bind9-dnsutils \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd --gid 65532 sdr \
    && useradd --uid 65532 --gid 65532 --create-home --home-dir /home/sdr --shell /bin/bash sdr
COPY --from=readsb /usr/bin/readsb /usr/local/bin/readsb
COPY --from=ais-catcher /usr/bin/AIS-catcher /usr/local/bin/AIS-catcher
USER 65532:65532
WORKDIR /home/sdr
CMD ["sleep", "infinity"]
