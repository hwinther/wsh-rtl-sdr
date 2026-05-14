ARG DOCKER_REGISTRY=ghcr.io/hwinther/proxmox/sdr/
FROM ${DOCKER_REGISTRY}sdr-base-wsh:bullseye AS runtime
FROM ${DOCKER_REGISTRY}sdr-build-wsh:bullseye AS build

FROM build AS build-dump1090-fa
WORKDIR /src
RUN git clone https://github.com/edgeofspace/dump1090-fa.git
WORKDIR /src/dump1090-fa
RUN ./prepare-build.sh bullseye
WORKDIR /src/dump1090-fa/package-bullseye
RUN dpkg-buildpackage -b --no-sign
RUN mkdir -p /opt/packages
RUN cp -f /src/dump1090-fa/*.deb /opt/packages

FROM runtime AS install
COPY --from=build-dump1090-fa /opt/packages /opt/packages
RUN apt -y install /opt/packages/*.deb && \
    rm -f /opt/packages/*.deb && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
RUN mkdir -p /etc/dump1090-fa && mkdir -p /run/dump1090-fa
COPY --from=build-dump1090-fa /src/dump1090-fa/wisdom.aarch64 /opt/dump1090-fa/wisdom.aarch64
COPY --from=build-dump1090-fa /src/dump1090-fa/wisdom.arm /opt/dump1090-fa/wisdom.arm
COPY --from=build-dump1090-fa /src/dump1090-fa/wisdom.generic /opt/dump1090-fa/wisdom.generic
COPY --from=build-dump1090-fa /src/dump1090-fa/wisdom.x86 /opt/dump1090-fa/wisdom.x86
COPY wisdom.rpi3b /opt/dump1090-fa/wisdom.rpi3b
# This can be used to generate the wisdom file for the current architecture
# RUN /usr/share/dump1090-fa/generate-wisdom > /etc/dump1090-fa/wisdom.local
ARG TARGETARCH
RUN case "${TARGETARCH}" in \
    amd64) cp /opt/dump1090-fa/wisdom.x86 /etc/dump1090-fa/wisdom.local ;; \
    arm64) cp /opt/dump1090-fa/wisdom.aarch64 /etc/dump1090-fa/wisdom.local ;; \
    *) echo "Unsupported TARGETARCH: $TARGETARCH" && exit 1 ;; \
    esac
COPY --chmod=755 start-dump1090-fa.sh /srv/start-dump1090-fa.sh

#region lighttpd
COPY <<EOF /etc/s6-overlay/s6-rc.d/lighttpd/type
longrun
EOF
COPY --chmod=700 <<EOF /etc/s6-overlay/s6-rc.d/lighttpd/run
#!/command/execlineb -P
/usr/sbin/lighttpd -f /etc/lighttpd/lighttpd.conf -D
EOF
RUN touch /etc/s6-overlay/s6-rc.d/user/contents.d/lighttpd
#endregion lighttpd

ENV DEVICE_TYPE="rtlsdr"
ENV DEVICE_INDEX="00000000"
ENV LAT="50.0"
ENV LON="10"
ENV EXTRA_ARGS="--quiet"

# Lighttpd HTTP server
EXPOSE 80
# TCP raw output listen port
EXPOSE 30002
# TCP BaseStation output listen port
EXPOSE 30003
# TCP Beast input listen ports
EXPOSE 30004
EXPOSE 30104
# TCP Beast output listen port
EXPOSE 30005

HEALTHCHECK --start-period=5s --interval=30s --timeout=5s --retries=3 CMD ["bash", "-c", "cat < /dev/null > /dev/tcp/localhost/30005"]
ENTRYPOINT [ "/init" ]
CMD [ "/srv/start-dump1090-fa.sh" ]