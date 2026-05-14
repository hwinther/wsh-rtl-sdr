# Digest-pinned so Dependabot tracks sdr-base updates. Runtime-only feeder (no compile step).
FROM ghcr.io/hwinther/wsh-rtl-sdr/sdr-base:bookworm@sha256:ceff4a5d96c64d590aa911986e09374d77295110237ce441283239bbcfde418b AS runtime

FROM runtime AS install-flightradar24
ARG TARGETPLATFORM
ARG TARGETARCH
ARG TARGETVARIANT
ARG FR24FEED_VERSION="1.0.48-0"
RUN mkdir /tmp/fr24feed && \
    if [ "$TARGETARCH" = "amd64" ]; then \
    wget -O /tmp/fr24feed/fr24feed.tgz https://repo-feed.flightradar24.com/linux_binaries/fr24feed_${FR24FEED_VERSION}_amd64.tgz && \
    cd /tmp/fr24feed && \
    tar -zxvf fr24feed.tgz && \
    rm -f fr24feed.tgz && \
    mv fr24feed_amd64 /opt/fr24feed; \
    elif [ "$TARGETARCH" = "arm64" ]; then \
    wget -O /tmp/fr24feed/fr24feed.tgz https://repo-feed.flightradar24.com/rpi_binaries/fr24feed_${FR24FEED_VERSION}_armhf.tgz && \
    cd /tmp/fr24feed && \
    tar -zxvf fr24feed.tgz && \
    rm -f fr24feed.tgz && \
    mv fr24feed_armhf /opt/fr24feed; \
    else \
    echo "Unsupported architecture: $ARCH" && exit 1; \
    fi && \
    /opt/fr24feed/fr24feed --version && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

FROM install-flightradar24 AS final
COPY --chmod=755 start-fr24feed.sh /srv/start-fr24feed.sh

ENV RECEIVER_TYPE="avr-tcp"
ENV RECEIVER_HOST="dump1090-fa"
ENV RECEIVER_PORT="30002"

HEALTHCHECK --start-period=10s --interval=30s --timeout=5s --retries=3 CMD ["bash", "-c", "fr24feed-status | grep 'FR24 Link: connected' || exit 1"]
ENTRYPOINT [ "/init" ]
CMD [ "/srv/start-fr24feed.sh" ]