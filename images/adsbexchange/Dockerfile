ARG DOCKER_REGISTRY=ghcr.io/hwinther/proxmox/sdr/
FROM ${DOCKER_REGISTRY}sdr-base-wsh:bookworm AS runtime
FROM ${DOCKER_REGISTRY}sdr-build-wsh:bookworm AS build

FROM build AS build-adsbexchange

COPY <<EOF /etc/default/adsbexchange
INPUT="127.0.0.1:30005"
REDUCE_INTERVAL="0.5"

# feed name for checking MLAT sync (adsbx.org/sync)
# also displayed on the MLAT map: map.adsbexchange.com/mlat-map
USER="0"

LATITUDE="59"
LONGITUDE="10"

ALTITUDE="0"

# this is the source for 978 data, use port 30978 from dump978 --raw-port
# if you're not receiving 978, don't worry about it, not doing any harm!
UAT_INPUT="127.0.0.1:30978"

RESULTS="--results beast,connect,127.0.0.1:30104"
RESULTS2="--results basestation,listen,31003"
RESULTS3="--results beast,listen,30157"
RESULTS4="--results beast,connect,127.0.0.1:30154"
# add --privacy between the quotes below to disable having the feed name shown on the mlat map
# (position is never shown accurately no matter the settings)
PRIVACY=""
INPUT_TYPE="dump1090"

MLATSERVER="feed.adsbexchange.com:31090"
TARGET="--net-connector feed1.adsbexchange.com,30004,beast_reduce_out,feed2.adsbexchange.com,64004"
NET_OPTIONS="--net-heartbeat 60 --net-ro-size 1280 --net-ro-interval 0.2 --net-ro-port 0 --net-sbs-port 0 --net-bi-port 30154 --net-bo-port 0 --net-ri-port 0 --write-json-every 1"
JSON_OPTIONS="--max-range 450 --json-location-accuracy 2 --range-outline-hours 24"
EOF

COPY --chmod=755 <<EOF /usr/bin/systemctl
#!/bin/bash
echo "Fake systemctl called with: \$@"
EOF
COPY --chmod=755 <<EOF /usr/bin/journalctl
#!/bin/bash
echo "Fake journalctl called with: \$@"
EOF

RUN mkdir -p /usr/local/share/adsbexchange && \
    cd /usr/local/share/adsbexchange && \
    git clone https://github.com/ADSBexchange/feedclient.git git && \
    bash git/update.sh && \
    apt-get clean

FROM runtime AS install-adsbexchange
RUN apt-get -y install libncurses6 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
COPY --from=build-adsbexchange /usr/local/share/adsbexchange /usr/local/share/adsbexchange

FROM install-adsbexchange AS final
COPY --chmod=755 start-adsbexchange.sh /srv/start-adsbexchange.sh
# COPY --chmod=755 start-adsbexchange-json-status.sh /srv/start-adsbexchange-json-status.sh

#region json-status
# COPY <<EOF /etc/s6-overlay/s6-rc.d/json-status/type
# longrun
# EOF
# COPY --chmod=700 <<EOF /etc/s6-overlay/s6-rc.d/json-status/run
# #!/command/execlineb -P
# /srv/start-adsbexchange-json-status.sh
# EOF
# RUN touch /etc/s6-overlay/s6-rc.d/user/contents.d/json-status
# #endregion json-status

ENV RECEIVER_HOST="dump1090-fa"
ENV RECEIVER_PORT="30005"
ENV MLAT_BEAST_HOST="dump1090-fa"
ENV MLAT_BEAST_PORT="30104"

# HEALTHCHECK --start-period=10s --interval=30s --timeout=5s --retries=3 CMD ["bash", "-c", "fr24feed-status | grep 'FR24 Link: connected' || exit 1"]
ENTRYPOINT [ "/init" ]
CMD [ "/srv/start-adsbexchange.sh" ]