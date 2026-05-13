# syntax=docker/dockerfile:1
#
# Parameterized SDR runtime base image. One Dockerfile, multiple Debian releases —
# the matrix in .github/workflows/build-sdr-images.yaml drives DEBIAN_RELEASE.
#
# Build:   docker build --build-arg DEBIAN_RELEASE=trixie .
# Buster:  add --build-arg USE_ARCHIVE_REPOS=true (buster has been moved to archive.debian.org).
#
# Consumed by downstream feeder images (dump1090-fa, piaware, tar1090, AIS-catcher, …) and
# by sdr-build/Dockerfile (full build toolchain). Long-term plan is to standardize on the
# newest Debian; the buster/bullseye/bookworm matrix entries exist for in-flight consumers.

ARG DEBIAN_RELEASE=trixie

FROM debian:${DEBIAN_RELEASE}-slim AS base
LABEL maintainer="Hans Christian Winther-Sørensen <docker@wsh.no>"
ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-x", "-o", "pipefail", "-c"]

ARG USE_ARCHIVE_REPOS=false
RUN set -eux; \
    if [ "${USE_ARCHIVE_REPOS}" = "true" ]; then \
        sed -i 's|deb.debian.org|archive.debian.org|g; s|security.debian.org|archive.debian.org|g' \
            /etc/apt/sources.list 2>/dev/null || true; \
        if [ -d /etc/apt/sources.list.d ]; then \
            sed -i 's|deb.debian.org|archive.debian.org|g; s|security.debian.org|archive.debian.org|g' \
                /etc/apt/sources.list.d/*.list /etc/apt/sources.list.d/*.sources 2>/dev/null || true; \
        fi; \
    fi; \
    apt-get update; \
    apt-get -y full-upgrade

FROM base AS runtime
ARG TARGETPLATFORM
ARG TARGETARCH
ARG TARGETVARIANT
RUN echo ${TARGETPLATFORM} > /srv/target.platform && \
    echo ${TARGETARCH} > /srv/target.arch && \
    echo ${TARGETVARIANT} > /srv/target.variant && \
    apt-get -y install curl gettext-base nano net-tools procps socat wget xz-utils && \
    apt-get clean

ARG S6_OVERLAY_VERSION=3.2.0.2
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz /tmp
RUN case "${TARGETARCH}" in \
    amd64) ARCH="x86_64" ;; \
    arm64) ARCH="aarch64" ;; \
    *) echo "Unsupported TARGETARCH: $TARGETARCH" && exit 1 ;; \
    esac && \
    wget -q https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-${ARCH}.tar.xz -O /tmp/s6-overlay-${ARCH}.tar.xz && \
    tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz && \
    tar -C / -Jxpf /tmp/s6-overlay-${ARCH}.tar.xz && \
    rm -f /tmp/*.tar.xz

ENTRYPOINT [ "bash" ]
