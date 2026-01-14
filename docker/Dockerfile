FROM debian:trixie AS base
LABEL maintainer="Hans Christian Winther-Sørensen <docker@wsh.no>"
ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-x", "-o", "pipefail", "-c"]
RUN apt-get update && \
    apt-get -y full-upgrade

FROM base AS runtime
RUN apt-get -y install curl gettext-base nano net-tools procps socat wget xz-utils && \
    apt-get clean
ENV S6_OVERLAY_VERSION="3.2.0.2"
ARG ARCH="x86_64"
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz /tmp
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-${ARCH}.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz && \
    tar -C / -Jxpf /tmp/s6-overlay-${ARCH}.tar.xz && \
    rm -f /tmp/*.tar.xz

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
    python3-build \
    python3-dev \
    python3-pip \
    python3-setuptools \
    python3-venv \
    python3-wheel \
    tcl8.6-dev && \
    apt-get clean

FROM install-build-deps AS build-rtl-sdr
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
WORKDIR /src
RUN git clone https://github.com/steve-m/kalibrate-rtl.git
WORKDIR /src/kalibrate-rtl
RUN apt-get -y install libtool libfftw3-dev && \
    ./bootstrap && \
    CXXFLAGS='-W -Wall -O3' ./configure && \
    make && \
    make install

FROM build-kalibrate-rtl AS gnuradio-dep
RUN apt-get -y install gnuradio-dev && \
    apt-get clean

FROM gnuradio-dep AS build-gr-gsm
RUN apt-get -y install cmake autoconf libtool pkg-config build-essential libcppunit-dev swig doxygen liblog4cpp5-dev gnuradio-dev gr-osmosdr libosmocore-dev python3-scipy && \
    apt-get clean
WORKDIR /src
RUN git clone https://github.com/bkerler/gr-gsm.git
WORKDIR /src/gr-gsm
#RUN apt-get -y install gnuradio-dev && \
RUN mkdir build && \
    cd build && \
    cmake .. && \
    make && \
    make install && \
    ldconfig

FROM build-gr-gsm AS build-lte-cell-scanner
WORKDIR /src
RUN git clone https://github.com/JiaoXianjun/LTE-Cell-Scanner.git
WORKDIR /src/LTE-Cell-Scanner
RUN apt-get -y install libitpp-dev opencl-headers libblas-dev liblapack-dev && \
    mkdir build && \
    cd build && \
    cmake ../ -DUSE_BLADERF=1 -DUSE_HACKRF=1 -DUSE_OPENCL=1 && \
    make && \
    make install

FROM build-lte-cell-scanner AS build-gr-iridium
WORKDIR /src
RUN git clone https://github.com/muccc/gr-iridium.git
WORKDIR /src/gr-iridium
RUN apt-get -y install gnuradio-dev libvolk-dev pybind11-dev libsndfile1-dev && \
    cmake -B build && \
    cmake --build build && \
    cmake --install build && \
    ldconfig

FROM build-gr-iridium AS final
WORKDIR /srv
RUN apt-get -y install termshark tshark tmux && \
    python3 -m venv venv3 && \
    source venv3/bin/activate && \
    pip3 install pyshark
COPY tmux-gsm-monitor.sh /srv/tmux-gsm-monitor.sh
RUN chmod +x /srv/tmux-gsm-monitor.sh

ADD https://github.com/zellij-org/zellij/releases/download/v0.41.2/zellij-x86_64-unknown-linux-musl.tar.gz /tmp
RUN cd /tmp && \
    tar -zxvf /tmp/zellij-x86_64-unknown-linux-musl.tar.gz && \
    mv zellij /usr/local/bin && \
    rm -f /tmp/zellij-x86_64-unknown-linux-musl.tar.gz

ENTRYPOINT [ "bash" ]
# ENTRYPOINT [ "/usr/local/bin/zellij" ]
