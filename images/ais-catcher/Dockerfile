# syntax=docker/dockerfile:1
#
# AIS-catcher built from pinned upstream source as one static (musl) binary on distroless: no shell,
# no package manager, no libraries beside it. Only what the edge deployment uses is compiled in:
# RTL-SDR, the web UI and API (with Prometheus at /metrics), MQTT, UDP and the aiscatcher.org feed,
# none of which needs TLS. Airspy, HackRF, SDRplay, ZMQ, Postgres, SQLite, OpenSSL and the rest
# are off.
#
# Cross-compiled with tonistiigi/xx (clang for the target, musl sysroot from Alpine), so the arm64
# build runs at native speed on an amd64 runner instead of under QEMU.
#
# Updates: Dependabot bumps the alpine, xx and distroless digests; .github/workflows/
# bump-sources.yml opens a PR when AIS-catcher's main moves. Either change touches this
# directory, so the merge rebuilds the image.

# AIS-catcher follows upstream main: releases are rare, and upstream itself only maintains the
# image it builds from main (`edge`). bump-sources.yml moves this to the newest main commit at least
# 7 days old (Dependabot's cooldown), one PR a week.
ARG AIS_CATCHER_REF=9739b81caf540e0e67b98447899cb28905a4f909

FROM --platform=$BUILDPLATFORM tonistiigi/xx:1.10.0@sha256:40fe21f44bb8cddf1eb1226db190d0a984118f62ee02a91b77d99448d28264a6 AS xx

FROM --platform=$BUILDPLATFORM alpine:3.24@sha256:be2656061b536c1883c4034790e21d0a09c5aaaf51968b89368a3c0371ea2c9a AS build
COPY --from=xx / /
RUN apk add --no-cache clang lld cmake make git pkgconf
ARG TARGETPLATFORM
# The target's static archives: librtlsdr (osmocom) and libusb (built without udev) from Alpine,
# so the builder's apk database records their versions for the SBOM below.
RUN xx-apk add --no-cache musl-dev gcc g++ linux-headers librtlsdr-dev libusb-dev zlib-dev zlib-static

ARG AIS_CATCHER_REF
ADD --keep-git-dir=true https://github.com/jvde-github/AIS-catcher.git#${AIS_CATCHER_REF} /src

WORKDIR /build
RUN cmake -S /src -B /build $(xx-clang --print-cmake-defines) \
        -DCMAKE_BUILD_TYPE=Release -DCMAKE_EXE_LINKER_FLAGS=-s \
        -DPKG_CONFIG_EXECUTABLE=$(xx-info triple)-pkg-config \
        -DSTATIC=ON \
        -DRTLSDR=ON -DZLIB=ON -DWEBVIEWER=ON -DAPI=ON \
        -DAIRSPY=OFF -DAIRSPYHF=OFF -DHACKRF=OFF -DHYDRASDR=OFF -DSDRPLAY=OFF -DSOAPYSDR=OFF \
        -DSOXR=OFF -DSAMPLERATE=OFF -DZMQ=OFF -DPSQL=OFF -DSQLITE=OFF -DOPENSSL=OFF \
        -DNMEA2000=OFF -DDELIVERY=OFF && \
    cmake --build /build -j"$(nproc)" && \
    xx-verify --static /build/AIS-catcher

# A CycloneDX SBOM of what is compiled into the binary. A static image has no package database, so
# without it Grype and Kubescape (scanEmbeddedSBOMs) would see none of these libraries.
COPY --chmod=755 sbom.sh /usr/local/bin/sbom.sh
RUN sbom.sh ais-catcher "$AIS_CATCHER_REF" https://github.com/jvde-github/AIS-catcher \
        librtlsdr libusb zlib musl libstdc++ libgcc > /build/ais-catcher.cdx.json

FROM gcr.io/distroless/static-debian13:nonroot@sha256:25ac8f0c3b2334a9eb05452266bd4697864a8c8ef0ef71e5e6480d7f92868329
LABEL maintainer="Hans Christian Winther-Sørensen <docker@wsh.no>"
COPY --from=build /build/AIS-catcher /usr/bin/AIS-catcher
COPY --from=build /build/ais-catcher.cdx.json /usr/share/sbom/ais-catcher.cdx.json
COPY ais-catcher-plugins /usr/share/aiscatcher/my-plugins

# The web UI, API and /metrics. The command line comes from the Deployment's args.
EXPOSE 8080
ENTRYPOINT ["/usr/bin/AIS-catcher"]
