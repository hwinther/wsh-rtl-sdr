# dump1090-exporter: reads dump1090-fa's stats.json / aircraft.json / receiver.json (shared
# /run/dump1090-fa emptyDir when run as a sidecar) and exposes Prometheus metrics on :9105 —
# message rate, aircraft counts, max range, signal levels. Persists reception history in
# Prometheus where the dump1090-fa web UI loses it on pod restart.
#
# Built on sdr-base (digest-pinned so Dependabot tracks the bump) for supply-chain consistency with
# the other feeders — it carries the same reusable-workflow attestations, so the cluster's cosign /
# SLSA policies admit it without a skip. It needs no SDR runtime itself, just python3 + the
# dump1090exporter package (installed in a venv; trixie's system python is PEP 668 managed).
FROM ghcr.io/hwinther/wsh-rtl-sdr/sdr-base:trixie@sha256:5153edec334357aef8634ad5f9d1c02fca05b204fc71a130c3db5c117896056a AS runtime
LABEL maintainer="Hans Christian Winther-Sørensen <docker@wsh.no>"
ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-x", "-o", "pipefail", "-c"]

# --no-deps because dump1090exporter 22.3.0 (latest release, upstream unmaintained since 2022)
# hard-pins aiohttp==3.8.1, whose C extensions predate Python 3.13 and can't even compile against
# it. Its only real requirements are aiohttp + aioprometheus[aiohttp]==22.3.0 (whose own extra is
# a loose aiohttp>=3.3.2), so we supply a modern aiohttp with prebuilt cp313 wheels for both
# amd64 and aarch64 ourselves — no gcc needed. Bump the aiohttp pin manually when rebuilding.
RUN apt-get update && \
    apt-get install -y --no-install-recommends python3 python3-venv && \
    python3 -m venv /opt/dump1090exporter && \
    /opt/dump1090exporter/bin/pip install --no-cache-dir --no-deps dump1090exporter==22.3.0 && \
    /opt/dump1090exporter/bin/pip install --no-cache-dir "aioprometheus[aiohttp]==22.3.0" aiohttp==3.14.1 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY --chmod=755 start-dump1090-exporter.sh /srv/start-dump1090-exporter.sh

# Defaults — override via env / k8s ConfigMap + Secret. RESOURCE_PATH may be a filesystem dir
# (sidecar sharing dump1090-fa's /run emptyDir) or an http URL to a /data endpoint.
# LAT/LON refine range calculations; unset falls back to receiver.json's position.
ENV RESOURCE_PATH="/run/dump1090-fa" \
    EXPORTER_PORT="9105" \
    LAT="" \
    LON=""

EXPOSE 9105
CMD ["/srv/start-dump1090-exporter.sh"]
