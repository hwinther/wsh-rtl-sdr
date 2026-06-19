# Digest-pinned so Dependabot tracks sdr-base/sdr-build updates.
FROM ghcr.io/hwinther/wsh-rtl-sdr/sdr-base:trixie@sha256:5153edec334357aef8634ad5f9d1c02fca05b204fc71a130c3db5c117896056a AS runtime
FROM ghcr.io/hwinther/wsh-rtl-sdr/sdr-build:trixie@sha256:b6a3cb25482e9b1f54d64885e9ac6543069a9cdcb77186a8b0dde3b64d9214ce AS build

FROM build AS build-piaware
WORKDIR /src
RUN git clone https://github.com/flightaware/piaware_builder.git
WORKDIR /src/piaware_builder
RUN ./sensible-build.sh trixie
WORKDIR /src/piaware_builder/package-trixie
# trixie's debian/control declares build-deps (python3-filelock,
# python3-pyasyncore, ...) not present in the base image. build-dep reads the
# generated control and installs exactly what this distribution requires.
RUN apt-get update && \
    apt-get -y build-dep . && \
    dpkg-buildpackage -b --no-sign && \
    apt-get clean && \
    mkdir -p /opt/packages && \
    cp -f /src/piaware_builder/*.deb /opt/packages

FROM build AS build-piaware-web
WORKDIR /src
RUN git clone https://github.com/flightaware/piaware-web.git
WORKDIR /src/piaware-web
# piaware-web's prepare-build.sh has no trixie case yet ("Don't know how to
# build for a distribution named trixie"). bookworm is its newest target and
# only sets a changelog distribution -- piaware-web ships static web assets,
# so the resulting .deb installs cleanly on the trixie runtime regardless.
RUN ./prepare-build.sh bookworm
WORKDIR /src/piaware-web/package-bookworm
RUN apt-get update && \
    apt-get -y build-dep . && \
    dpkg-buildpackage -b --no-sign && \
    apt-get clean && \
    mkdir -p /opt/packages && \
    cp -f /src/piaware-web/*.deb /opt/packages

FROM runtime AS install
COPY --from=build-piaware /opt/packages /opt/packages
COPY --from=build-piaware-web /opt/packages /opt/packages
# apt-get update is required here: the parent layer cleaned /var/lib/apt/lists,
# and the .deb dependencies pull packages whose binNMU versions Debian
# routinely supersedes (e.g. libpam-cap +b2 -> +b3), 404'ing without a refresh.
RUN apt-get update && \
    apt -y install /opt/packages/*.deb && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

FROM install AS final
RUN mkdir -p /run/piaware
COPY --chmod=755 start-piaware.sh /srv/start-piaware.sh

#region lighttpd
COPY <<EOF /etc/s6-overlay/s6-rc.d/lighttpd/type
longrun
EOF
COPY --chmod=700 <<EOF /etc/s6-overlay/s6-rc.d/lighttpd/run
#!/command/execlineb -P
/usr/sbin/lighttpd -f /etc/lighttpd/lighttpd.conf -D
EOF
RUN touch /etc/s6-overlay/s6-rc.d/user/contents.d/lighttpd && \
    mkdir -p /etc/s6-overlay/s6-rc.d/lighttpd/dependencies.d && \
    touch /etc/s6-overlay/s6-rc.d/lighttpd/dependencies.d/piaware
#endregion lighttpd

#region socat-30005
COPY <<EOF /etc/s6-overlay/s6-rc.d/socat-30005/type
longrun
EOF
COPY --chmod=700 <<EOF /etc/s6-overlay/s6-rc.d/socat-30005/run
#!/command/execlineb -P
socat -U TCP-LISTEN:30005,reuseaddr,fork TCP-CONNECT:dump1090-fa:30005
EOF
RUN touch /etc/s6-overlay/s6-rc.d/user/contents.d/socat-30005
#endregion socat-30005

#region socat-30104
COPY <<EOF /etc/s6-overlay/s6-rc.d/socat-30104/type
longrun
EOF
COPY --chmod=700 <<EOF /etc/s6-overlay/s6-rc.d/socat-30104/run
#!/command/execlineb -P
socat -U TCP-LISTEN:30104,reuseaddr,fork TCP-CONNECT:dump1090-fa:30104
EOF
RUN touch /etc/s6-overlay/s6-rc.d/user/contents.d/socat-30104
#endregion socat-30104

#region piaware
COPY <<EOF /etc/s6-overlay/s6-rc.d/piaware/type
longrun
EOF
COPY --chmod=700 <<EOF /etc/s6-overlay/s6-rc.d/piaware/run
#!/command/execlineb -P
/srv/start-piaware.sh
EOF
RUN touch /etc/s6-overlay/s6-rc.d/user/contents.d/piaware
#endregion piaware

# https://www.flightaware.com/adsb/piaware/advanced_configuration
ENV RECEIVER_TYPE="other"
ENV RECEIVER_HOST="dump1090-fa"
ENV RECEIVER_PORT="30005"
ENV MLAT_BEAST_HOST="dump1090-fa"
ENV MLAT_BEAST_PORT="30104"
ENV DEBUG="false"

# Lighttpd HTTP server
EXPOSE 80
# Beast output listen port
EXPOSE 30105
# Basestation output listen port
EXPOSE 30106

HEALTHCHECK --start-period=5s --interval=30s --timeout=5s --retries=3 CMD ["bash", "-c", "if [ -f /run/piaware/piaware.pid ]; then PID=$(cat /run/piaware/piaware.pid); if ps -p $PID > /dev/null; then exit 0; else exit 1; fi; else exit 1; fi"]
ENTRYPOINT [ "/init" ]
# CMD [ "/srv/start-piaware.sh" ]