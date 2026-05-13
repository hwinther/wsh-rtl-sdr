# syntax=docker/dockerfile:1
#
# Parameterized SDR build image: extends sdr-base with the SDR build toolchain (autotools,
# CMake, debhelper, boost, librtlsdr-dev, libhackrf-dev, …) and optionally python3-build/dev
# tooling. One Dockerfile, multiple Debian releases.
#
# Inherits from sdr-base/Dockerfile, so the apt upgrade, USE_ARCHIVE_REPOS sources rewrite,
# /srv/target.* metadata, and s6-overlay are all in place via the parent image.
#
# Build:   docker build \
#              --build-arg DEBIAN_RELEASE=trixie \
#              --build-arg SDR_BASE=ghcr.io/hwinther/wsh-rtl-sdr/sdr-base:trixie .
# Buster:  add --build-arg INSTALL_PYTHON_BUILD_TOOLS=false
#          (python3-build is not packaged on buster).

ARG DEBIAN_RELEASE=trixie
ARG SDR_BASE=ghcr.io/hwinther/wsh-rtl-sdr/sdr-base:${DEBIAN_RELEASE}

FROM ${SDR_BASE} AS base
LABEL maintainer="Hans Christian Winther-Sørensen <docker@wsh.no>"

FROM base AS install-build-deps
RUN apt-get update && apt-get -y install \
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
