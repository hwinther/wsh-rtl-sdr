# syntax=docker/dockerfile:1
#
# Parameterized SDR build image (full Debian, not -slim — adds the SDR build toolchain on
# top of the runtime stage). Same parameterization as images/sdr-base/Dockerfile.
#
# Build:   docker build --build-arg DEBIAN_RELEASE=trixie .
# Buster:  add --build-arg USE_ARCHIVE_REPOS=true --build-arg INSTALL_PYTHON_BUILD_TOOLS=false
#          (buster's apt repo lacks `python3-build`; other python3-* packages were not
#          installed on buster historically, so the whole block stays off for parity.)
#
# Used by:
# - Feeder image builds in this repo (dump1090-fa, piaware, tar1090, AIS-catcher, …)
# - docker/Dockerfile (gsm-tools) — once that image is refactored to FROM this base instead
#   of re-installing the same lib*-dev + python3-* set inline.

ARG DEBIAN_RELEASE=trixie

FROM debian:${DEBIAN_RELEASE} AS base
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

FROM runtime AS install-build-deps
RUN apt-get -y install \
    autoconf \
    build-essential \
    cmake \
    debhelper \
    devscripts \
    fakeroot \
    git \
    libbladerf-dev \
    libboost-filesystem-dev \
    libboost-program-options-dev \
    libboost-regex-dev \
    libboost-system-dev \
    libhackrf-dev \
    liblimesuite-dev \
    libncurses5-dev \
    librtlsdr-dev \
    libusb-dev \
    libz-dev \
    openssl \
    patchelf \
    pkg-config \
    tcl8.6-dev && \
    apt-get clean

ARG INSTALL_PYTHON_BUILD_TOOLS=true
RUN set -eux; \
    if [ "${INSTALL_PYTHON_BUILD_TOOLS}" = "true" ]; then \
        apt-get -y install \
            python3-build \
            python3-dev \
            python3-pip \
            python3-setuptools \
            python3-venv \
            python3-wheel; \
        apt-get clean; \
    fi

ENTRYPOINT [ "bash" ]
