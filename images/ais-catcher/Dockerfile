FROM ghcr.io/jvde-github/ais-catcher:v0.68 AS base
LABEL maintainer="Hans Christian Winther-Sørensen <docker@wsh.no>"
ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-x", "-o", "pipefail", "-c"]

RUN apt-get update && \
    apt-get install -y curl nano wget && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
COPY --chmod=755 start-ais-catcher.sh /srv/start-ais-catcher.sh
COPY ais-catcher-plugins /usr/share/aiscatcher/my-plugins
ARG TARGETPLATFORM
ARG TARGETARCH
ARG TARGETVARIANT
RUN echo ${TARGETPLATFORM} > /srv/target.platform && \
    echo ${TARGETARCH} > /srv/target.arch && \
    echo ${TARGETVARIANT} > /srv/target.variant

ENV AIS_CATCHER_PORT=8100
ENV STATION_NAME="AIS-Catcher"
ENV STATION_URL="https://google.com"
ENV DEVICE_INDEX=00000001
ENV BIASTEE=off
ENV EXTRA_ARGS=""

# AIS-Catcher http port
EXPOSE $AIS_CATCHER_PORT

HEALTHCHECK --start-period=5s --interval=30s --timeout=5s --retries=3 CMD ["bash", "-c", "cat < /dev/null > /dev/tcp/localhost/$AIS_CATCHER_PORT"]
ENTRYPOINT [ "/srv/start-ais-catcher.sh" ]
