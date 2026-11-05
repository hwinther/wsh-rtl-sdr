# syntax=docker/dockerfile:1
#
# readsb (wiedehopf) built from pinned upstream source as one static (musl) binary on distroless: no
# shell, no package manager, no libraries beside it. The ADS-B decoder for the edge Pi, replacing
# dump1090-fa: same network ports (raw 30002, SBS 30003, Beast in 30004/30104, Beast out 30005) and
# the same JSON directory for tar1090 and the feeders. Only RTL-SDR is compiled in (with bias-tee);
# no interactive (ncurses) mode, no BladeRF/HackRF/Pluto/Soapy.
#
# Cross-compiled with tonistiigi/xx (clang for the target, musl sysroot from Alpine), so the arm64
# build runs at native speed on an amd64 runner instead of under QEMU.
#
# Updates: Dependabot bumps the alpine, xx and distroless digests; .github/workflows/
# bump-sources.yml opens a PR when readsb's dev branch moves. Either change touches this directory,
# so the merge rebuilds the image.

# readsb follows upstream dev, where wiedehopf works and from which the community images build.
# bump-sources.yml moves this to the newest dev commit at least 7 days old (Dependabot's cooldown),
# one PR a week.
ARG READSB_REF=f36ff24493e9066a7bcdb131e18b2d461cd41b38

FROM --platform=$BUILDPLATFORM tonistiigi/xx:1.10.0@sha256:40fe21f44bb8cddf1eb1226db190d0a984118f62ee02a91b77d99448d28264a6 AS xx

FROM --platform=$BUILDPLATFORM alpine:3.24@sha256:be2656061b536c1883c4034790e21d0a09c5aaaf51968b89368a3c0371ea2c9a AS build
COPY --from=xx / /
RUN apk add --no-cache clang lld make git pkgconf
ARG TARGETPLATFORM
# The target's static archives: librtlsdr (osmocom) and libusb (built without udev), zstd and zlib
# from Alpine, so the builder's apk database records their versions for the SBOM below.
RUN xx-apk add --no-cache musl-dev gcc linux-headers librtlsdr-dev libusb-dev \
        zlib-dev zlib-static zstd-dev zstd-static

ARG READSB_REF
ADD --keep-git-dir=true https://github.com/wiedehopf/readsb.git#${READSB_REF} /src

WORKDIR /src
# RTLSDR_PREFIX points the Makefile at the target sysroot instead of the build host's pkg-config,
# and librtlsdr's private dependency (libusb) is linked explicitly for the static link.
RUN make -j"$(nproc)" readsb \
        CC=xx-clang \
        RTLSDR=yes HAVE_BIASTEE=yes DISABLE_INTERACTIVE=yes \
        RTLSDR_PREFIX="$(xx-info sysroot)usr" \
        LDFLAGS="-static -s" \
        LIBS_SDR="-lrtlsdr -lusb-1.0" && \
    xx-verify --static readsb

# A CycloneDX SBOM of what is compiled into the binary. A static image has no package database, so
# without it Grype and Kubescape (scanEmbeddedSBOMs) would see none of these libraries.
COPY --chmod=755 sbom.sh /usr/local/bin/sbom.sh
RUN sbom.sh readsb "$READSB_REF" https://github.com/wiedehopf/readsb \
        librtlsdr libusb zstd-libs zlib musl > /src/readsb.cdx.json

FROM gcr.io/distroless/static-debian13:nonroot@sha256:25ac8f0c3b2334a9eb05452266bd4697864a8c8ef0ef71e5e6480d7f92868329
LABEL maintainer="Hans Christian Winther-Sørensen <docker@wsh.no>"
COPY --from=build /src/readsb /usr/bin/readsb
COPY --from=build /src/readsb.cdx.json /usr/share/sbom/readsb.cdx.json

# Raw out, SBS out, Beast in (two ports), Beast out. The command line comes from the Deployment's args.
EXPOSE 30002 30003 30004 30104 30005
ENTRYPOINT ["/usr/bin/readsb"]
