# syntax=docker/dockerfile:1
#
# fr24: Flightradar24's fr24feed, a statically linked binary (glibc static, amd64 and arm64), on
# distroless/static: no shell, uid 65532. The configuration is fr24feed's own flags (the Deployment's
# args), so there is no start script and no /etc/fr24feed.ini:
#   --fr24key=<key> --receiver=avr-tcp --host=readsb:30002 --bs=no --raw=no --mlat=no
# Status (no key in it) is served on :8754 (/monitor.json), used as the health check.
#
# Updates: Dependabot bumps the debian, golang and distroless digests. .github/workflows/
# bump-fr24feed.yml moves FR24FEED_VERSION and both sha256 values weekly to the version
# https://repo-feed.flightradar24.com/fr24feed_versions.json lists, once it is 7 days old.

ARG FR24FEED_VERSION=1.0.57-1
ARG FR24FEED_SHA256_AMD64=7d746c4b32a2f82bb8dd2c7666e3f8eb7028e2833d603fc8a7a6907d6fae328d
ARG FR24FEED_SHA256_ARM64=8bfdef70dfb727d23bd20370889eb659adf10f51975699bf1297acc3440dc579

FROM --platform=$BUILDPLATFORM debian:trixie-slim@sha256:a72b4433de1cf7d6bae0c4cee74d0547f58601a643b3375f070c51600d63b6b2 AS download
ARG TARGETARCH
ARG FR24FEED_VERSION
ARG FR24FEED_SHA256_AMD64
ARG FR24FEED_SHA256_ARM64
RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates wget && \
    rm -rf /var/lib/apt/lists/*
RUN set -eu; \
    case "$TARGETARCH" in \
        amd64) dir=linux_binaries; sha="$FR24FEED_SHA256_AMD64" ;; \
        arm64) dir=rpi_binaries; sha="$FR24FEED_SHA256_ARM64" ;; \
        *) echo "unsupported architecture: $TARGETARCH" >&2; exit 1 ;; \
    esac; \
    wget -qO /tmp/fr24feed.tgz "https://repo-feed.flightradar24.com/${dir}/fr24feed_${FR24FEED_VERSION}_${TARGETARCH}.tgz"; \
    echo "${sha}  /tmp/fr24feed.tgz" | sha256sum -c -; \
    tar -xzf /tmp/fr24feed.tgz -C /tmp; \
    install -D -m 0755 "/tmp/fr24feed_${TARGETARCH}/fr24feed" /out/fr24feed

FROM --platform=$BUILDPLATFORM golang:1.27.3-alpine3.24@sha256:fa3d596898d9f126af7c01d14ee7597bab3f39cccf392ef36b69fe77cd681f18 AS noop-shell
ARG TARGETOS
ARG TARGETARCH
COPY noop-shell/main.go /src/main.go
RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH go build -trimpath -ldflags='-s -w' -o /out/noop-shell /src/main.go

FROM gcr.io/distroless/static-debian13:nonroot@sha256:aafe993665bf6200db38a02c11a9351e782a84b6a45e7f33b6695638c88e3931
LABEL maintainer="Hans Christian Winther-Sørensen <docker@wsh.no>"
COPY --from=noop-shell /out/noop-shell /bin/bash
COPY --from=download /out/fr24feed /usr/bin/fr24feed
EXPOSE 8754
ENTRYPOINT ["/usr/bin/fr24feed"]
CMD ["--receiver=avr-tcp", "--host=readsb:30002", "--bs=no", "--raw=no", "--mlat=no", "--mlat-without-gps=no"]
