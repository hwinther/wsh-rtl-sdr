# Digest-pinned so Dependabot tracks sdr-base/sdr-build updates. Buster is archived in
# Debian; sdr-base/sdr-build:buster handles the archive.debian.org sources rewrite.
FROM ghcr.io/hwinther/wsh-rtl-sdr/sdr-base:buster@sha256:88929ed1d90fdd23adb266e2a933105f1ffa3386bcade22a8cd5b2ff1a829188 AS runtime
FROM ghcr.io/hwinther/wsh-rtl-sdr/sdr-build:buster@sha256:76ecebbca3b1d043cea7b19d17b657f728ecdc39fd95b53d1b1237db1f360e19 AS build

FROM build AS install-build-deps
RUN apt-get -y install \
    autoconf-archive \
    dh-exec \
    dh-systemd && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

FROM install-build-deps AS build-opensky
WORKDIR /src
RUN git clone https://github.com/openskynetwork/opensky-sensor.git
WORKDIR /src/opensky-sensor
RUN dpkg-buildpackage -b --no-sign && \
    mkdir -p /opt/packages && \
    cp -f /src/opensky-feeder_*.deb /opt/packages && \
    cp -f /src/libopensky-c++1_*.deb /opt/packages
RUN ar vx /src/opensky-feeder_*.deb && \
    tar -C /tmp -Jxpf data.tar.xz && \
    mkdir -p /opt/bin && \
    cp -f /tmp/usr/bin/openskyd-dump1090 /opt/bin/openskyd-dump1090

FROM runtime AS install
# COPY --from=build-opensky /opt/packages /opt/packages
# RUN dpkg -i /opt/packages/*.deb && \
#     apt-get -y -f install && \
#     apt-get clean && \
#     rm -rf /var/lib/apt/lists/*
COPY --from=build-opensky /opt/bin/openskyd-dump1090 /usr/bin/openskyd-dump1090

# RUN apt-get -y install gnupg2 && \
#     wget -q  -O - https://opensky-network.org/files/firmware/opensky.gpg.pub | apt-key add - && \
#     echo deb https://opensky-network.org/repos/debian opensky custom > /etc/apt/sources.list.d/opensky.list && \
#     apt-get update -y && \
#     apt-get -y install opensky-sensor && \
#     apt-get clean && \
#     rm -rf /var/lib/apt/lists/*

FROM install AS final
COPY --chmod=755 start-opensky.sh /srv/start-opensky.sh

ENV RECEIVER_HOST="dump1090-fa"
ENV RECEIVER_PORT="30005"
ENV OPENSKY_DEVICE_TYPE="default"

#HEALTHCHECK --start-period=5s --interval=30s --timeout=5s --retries=3 CMD ["bash", "-c", "cat < /dev/null > /dev/tcp/localhost/30005"]
ENTRYPOINT [ "/init" ]
CMD [ "/srv/start-opensky.sh" ]