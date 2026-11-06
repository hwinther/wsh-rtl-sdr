# syntax=docker/dockerfile:1
#
# piaware: FlightAware's feeder (piaware, tcl) with faup1090 and fa-mlat-client (python), built from
# FlightAware's piaware_builder at a pinned tag into a .deb and installed on plain debian:trixie-slim.
# The runtime needs tcl and python, so no distroless; but no sdr-base, s6, lighttpd/piaware-web,
# socat or start script either: piaware itself is the entrypoint.
#
# Configuration: /etc/piaware.conf, mounted from the Deployment's Secret (it holds feeder-id).
# receiver-type=relay points faup1090 and fa-mlat-client straight at dump1090-fa:30005 (the old
# image proxied that to localhost with socat for receiver-type=other). piaware writes to
# /var/cache/piaware and /run/piaware, which must be writable (emptyDirs).
#
# Updates: Dependabot bumps the debian digest. A new piaware_builder tag is a manual PIAWARE_VERSION
# bump (https://github.com/flightaware/piaware_builder/tags).

ARG PIAWARE_VERSION=v11.1

FROM debian:trixie-slim@sha256:a72b4433de1cf7d6bae0c4cee74d0547f58601a643b3375f070c51600d63b6b2 AS build
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y --no-install-recommends build-essential ca-certificates debhelper devscripts \
        equivs git wget && \
    rm -rf /var/lib/apt/lists/*
ARG PIAWARE_VERSION
RUN git clone -c advice.detachedHead=false --depth=1 --branch "$PIAWARE_VERSION" \
        https://github.com/flightaware/piaware_builder.git /src
WORKDIR /src
# sensible-build.sh clones piaware, tcllauncher, dump1090 (faup1090) and mlat-client at the versions
# this piaware_builder tag pins, and writes package-trixie/debian; build-dep installs what that
# control file asks for.
RUN ./sensible-build.sh trixie && \
    cd package-trixie && \
    apt-get update && \
    apt-get -y build-dep . && \
    dpkg-buildpackage -b --no-sign && \
    mkdir -p /out && cp /src/piaware_*.deb /out/

FROM debian:trixie-slim@sha256:a72b4433de1cf7d6bae0c4cee74d0547f58601a643b3375f070c51600d63b6b2
LABEL maintainer="Hans Christian Winther-Sørensen <docker@wsh.no>"
ENV DEBIAN_FRONTEND=noninteractive
COPY --from=build /out/ /tmp/piaware/
RUN apt-get update && \
    apt-get install -y --no-install-recommends /tmp/piaware/piaware_*.deb && \
    rm -rf /var/lib/apt/lists/* /tmp/piaware && \
    install -d -o 65532 -g 65532 /var/cache/piaware /run/piaware

USER 65532:65532
ENTRYPOINT ["/usr/bin/piaware", "-plainlog", "-statusfile", "/run/piaware/status.json"]
