# syntax=docker/dockerfile:1
#
# gsm-tools: GSM/SDR analysis tooling, a developer tool (not deployed).
# Built layers: rtl-sdr + kalibrate-rtl + gr-gsm + LTE-Cell-Scanner + gr-iridium +
# pyshark + zellij + a tmux gsm-monitor script.
#
# On plain debian:trixie-slim with the SDR build toolchain (autoconf/cmake/debhelper/boost/
# libhackrf-dev/librtlsdr-dev/python3-*) installed here; this was the last user of the old
# sdr-base/sdr-build images. amd64 only: gnuradio, gr-gsm and gr-iridium took hours under QEMU.
#
# This image is monolithic — build deps remain in the final layer because it's used
# as an interactive container (`docker exec` into it), not a discardable build stage.
#
# Digest-pinned so Dependabot's docker ecosystem tracks debian updates.
FROM debian:trixie-slim@sha256:a72b4433de1cf7d6bae0c4cee74d0547f58601a643b3375f070c51600d63b6b2 AS base
LABEL maintainer="Hans Christian Winther-Sørensen <docker@wsh.no>"
ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-x", "-o", "pipefail", "-c"]
RUN apt-get update && \
    apt-get -y full-upgrade && \
    apt-get -y install --no-install-recommends \
    autoconf \
    automake \
    build-essential \
    ca-certificates \
    cmake \
    curl \
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
    libncurses-dev \
    librtlsdr-dev \
    libusb-1.0-0-dev \
    nano \
    net-tools \
    pkg-config \
    procps \
    python3-dev \
    python3-pip \
    python3-setuptools \
    python3-venv \
    python3-wheel \
    wget \
    xz-utils \
    zlib1g-dev && \
    apt-get clean

FROM base AS build-rtl-sdr
WORKDIR /src
RUN git clone https://github.com/osmocom/rtl-sdr.git
WORKDIR /src/rtl-sdr
RUN mkdir build && \
    cd build && \
    cmake ../ && \
    make && \
    make install && \
    ldconfig

FROM build-rtl-sdr AS build-kalibrate-rtl
# apt-get update is required: parent layer cleaned /var/lib/apt/lists,
# and Debian routinely supersedes the binNMU versions referenced there.
RUN apt-get update && \
    apt-get -y install libtool libfftw3-dev && \
    apt-get clean
WORKDIR /src
RUN git clone https://github.com/steve-m/kalibrate-rtl.git
WORKDIR /src/kalibrate-rtl
RUN ./bootstrap && \
    CXXFLAGS='-W -Wall -O3' ./configure && \
    make && \
    make install

FROM build-kalibrate-rtl AS gnuradio-dep
RUN apt-get update && \
    apt-get -y install gnuradio-dev && \
    apt-get clean

FROM gnuradio-dep AS build-gr-gsm
RUN apt-get update && \
    apt-get -y install \
    libcppunit-dev \
    swig \
    doxygen \
    liblog4cpp5-dev \
    gr-osmosdr \
    libosmocore-dev \
    python3-scipy && \
    apt-get clean
WORKDIR /src
RUN git clone https://github.com/bkerler/gr-gsm.git
WORKDIR /src/gr-gsm
RUN mkdir build && \
    cd build && \
    cmake .. && \
    make && \
    make install && \
    ldconfig

FROM build-gr-gsm AS build-lte-cell-scanner
RUN apt-get update && \
    apt-get -y install libitpp-dev opencl-headers libblas-dev liblapack-dev && \
    apt-get clean
WORKDIR /src
RUN git clone https://github.com/JiaoXianjun/LTE-Cell-Scanner.git
WORKDIR /src/LTE-Cell-Scanner
RUN mkdir build && \
    cd build && \
    cmake ../ -DUSE_BLADERF=1 -DUSE_HACKRF=1 -DUSE_OPENCL=1 && \
    make && \
    make install

FROM build-lte-cell-scanner AS build-gr-iridium
RUN apt-get update && \
    apt-get -y install libvolk-dev pybind11-dev libsndfile1-dev && \
    apt-get clean
WORKDIR /src
RUN git clone https://github.com/muccc/gr-iridium.git
WORKDIR /src/gr-iridium
RUN cmake -B build && \
    cmake --build build && \
    cmake --install build && \
    ldconfig

FROM build-gr-iridium AS final
WORKDIR /srv
RUN apt-get update && \
    apt-get -y install termshark tshark tmux && \
    apt-get clean && \
    python3 -m venv venv3 && \
    source venv3/bin/activate && \
    pip3 install pyshark
COPY tmux-gsm-monitor.sh /srv/tmux-gsm-monitor.sh
RUN chmod +x /srv/tmux-gsm-monitor.sh

ARG TARGETARCH
ARG ZELLIJ_VERSION=0.41.2
RUN case "${TARGETARCH}" in \
    amd64|"") arch="x86_64" ;; \
    arm64)    arch="aarch64" ;; \
    *) echo "Unsupported TARGETARCH: ${TARGETARCH}" && exit 1 ;; \
    esac && \
    curl -fsSL -o /tmp/zellij.tar.gz \
        "https://github.com/zellij-org/zellij/releases/download/v${ZELLIJ_VERSION}/zellij-${arch}-unknown-linux-musl.tar.gz" && \
    tar -C /tmp -zxf /tmp/zellij.tar.gz && \
    mv /tmp/zellij /usr/local/bin/ && \
    rm -f /tmp/zellij.tar.gz

ENTRYPOINT [ "bash" ]
# ENTRYPOINT [ "/usr/local/bin/zellij" ]
