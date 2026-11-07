# syntax=docker/dockerfile:1
#
# tar1090: wiedehopf's ADS-B map web UI as static files, served by wshno/static-server (a stdlib-only
# Go server on distroless: no shell, uid 65532, port 8080). static-server.json reproduces tar1090's
# nginx.conf headers. Tracks come from readsb itself, which runs with --write-json-globe-index
# (traces + globe files in its JSON directory), so tar1090.sh's bash history-chunk loop is not
# needed.
#
# The html stage does what tar1090's install.sh does to the html directory: add the aircraft database
# (tar1090-db) as db-<version>, write version.json, and cache-bust the js/css names. Per-deployment
# files are mounted at runtime, not baked in: config.js (e.g. aiscatcher_server; defaults.js has
# every default, so it only needs the overrides) and upintheair.json (HeyWhatsThat range rings).
# readsb's JSON directory is mounted read-only at /run/readsb and served under /data/.
#
# Updates: Dependabot bumps the static-server and alpine images. TAR1090_REF and TAR1090_DB_REF
# are manual bumps (wiedehopf/tar1090 and wiedehopf/tar1090-db master).

ARG TAR1090_REF=5d59b1ba2c5e30eb23f1161940367b7767f10ad5
ARG TAR1090_DB_REF=2ab834a65f2fbde9457823e88682cd46954b8bc1

FROM --platform=$BUILDPLATFORM alpine:3.24@sha256:be2656061b536c1883c4034790e21d0a09c5aaaf51968b89368a3c0371ea2c9a AS html
RUN apk add --no-cache bash coreutils sed
ARG TAR1090_REF
ARG TAR1090_DB_REF
ADD https://github.com/wiedehopf/tar1090.git#${TAR1090_REF} /src/tar1090
ADD https://github.com/wiedehopf/tar1090-db.git#${TAR1090_DB_REF} /src/tar1090-db
RUN set -eu; \
    out=/out/html; \
    tar_version="$(cat /src/tar1090/version)"; \
    db_version="$(cat /src/tar1090-db/version)"; \
    mkdir -p "$out"; \
    cp -r -T /src/tar1090/html "$out"; \
    cp -r -T /src/tar1090-db/db "$out/db-$db_version"; \
    sed -i -e "s/let databaseFolder = .*;/let databaseFolder = \"db-$db_version\";/" "$out/index.html"; \
    echo "{ \"tar1090Version\": \"$tar_version\", \"databaseVersion\": \"$db_version\" }" > "$out/version.json"; \
    cd "$out"; \
    sed -i -e 's/id="webinterface_version">/\0'"($tar_version)/" index.html; \
    bash /src/tar1090/cachebust.sh /src/tar1090/cachebust.list "$out"

FROM ghcr.io/wshno/static-server/server:0.1.0@sha256:9036422e3de9c774cc26a0f7ecf05e04bef2fea162653ec248691ee8c90abb94
LABEL maintainer="Hans Christian Winther-Sørensen <docker@wsh.no>"
COPY static-server.json /etc/static-server/config.json
COPY --from=html /out/html /usr/share/tar1090/html
