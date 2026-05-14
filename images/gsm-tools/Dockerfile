# syntax=docker/dockerfile:1
#
# gsm-tools: GSM/SDR analysis tooling on top of the shared sdr-build base.
# Built layers: rtl-sdr + kalibrate-rtl + gr-gsm + LTE-Cell-Scanner + gr-iridium +
# pyshark + zellij + a tmux gsm-monitor script.
#
# Inherits from sdr-build/Dockerfile via SDR_BUILD, which provides debian-trixie +
# apt-upgrade + /srv/target.* + runtime tools + s6-overlay + the standard SDR build
# toolchain (autoconf/cmake/debhelper/boost/libhackrf-dev/librtlsdr-dev/python3-*).
#
# This image is monolithic — build deps remain in the final layer because it's used
# as an interactive container (`docker exec` into it), not a discardable build stage.
#
# Digest-pinned so Dependabot's docker ecosystem tracks sdr-build updates.
# The tag (`:trixie`) tells Dependabot which channel to follow; the digest is the actual
# pin Docker resolves at build time. Dependabot opens PRs when the tag's digest advances.
FROM ghcr.io/hwinther/wsh-rtl-sdr/sdr-build:trixie@sha256:f4e598858e26521d50c57a728f381dd9ff670d2e59f3de71f34258ae1c8418a3 AS base
LABEL maintainer="Hans Christian Winther-Sørensen <docker@wsh.no>"
SHELL ["/bin/bash", "-x", "-o", "pipefail", "-c"]

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
RUN apt-get -y install libtool libfftw3-dev && \
    apt-get clean
WORKDIR /src
RUN git clone https://github.com/steve-m/kalibrate-rtl.git
WORKDIR /src/kalibrate-rtl
RUN ./bootstrap && \
    CXXFLAGS='-W -Wall -O3' ./configure && \
    make && \
    make install

FROM build-kalibrate-rtl AS gnuradio-dep
RUN apt-get -y install gnuradio-dev && \
    apt-get clean

FROM gnuradio-dep AS build-gr-gsm
RUN apt-get -y install \
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
RUN apt-get -y install libitpp-dev opencl-headers libblas-dev liblapack-dev && \
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
RUN apt-get -y install libvolk-dev pybind11-dev libsndfile1-dev && \
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
RUN apt-get -y install termshark tshark tmux && \
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
