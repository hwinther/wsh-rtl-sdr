# syntax=docker/dockerfile:1
#
# dump1090-exporter: reads readsb's stats.json / aircraft.json / receiver.json (the shared JSON
# directory when run as a sidecar) and exposes Prometheus metrics on :9105 — message rate, aircraft
# counts, max range, signal levels — so reception history survives pod restarts.
#
# Chainguard's Wolfi-based python (no shell or package manager, uid 65532), rebuilt daily on the
# current upstream CPython. Distroless python scanned as Debian's older python3.13 plus krb5, expat
# and libgomp: 4 critical and ~50 high, all "won't fix". The dependencies are pip-installed in the
# matching latest-dev builder into /opt/deps. Dependabot bumps the two digests together (base-images
# group) and requirements.txt (pip); either change rebuilds the image on merge.
#
# The free tier only publishes `latest`, so the Python minor can move with a digest bump (3.15 at the
# switch). Not --only-binary: a dependency without a wheel for that Python yet (frozenlist at 3.15)
# builds from its sdist, and FROZENLIST_NO_EXTENSIONS makes that the pure-Python version, so no
# compiler is needed. aiohttp and the rest come as prebuilt wheels.

FROM cgr.dev/chainguard/python:latest-dev@sha256:e2736acdf97f2b1cb59545f4f26317b18a953e90e59fa4c212a782315b248111 AS deps
# The -dev image runs as nonroot (65532); root is only needed to write /opt/deps.
USER root
COPY requirements.txt /tmp/requirements.txt
RUN FROZENLIST_NO_EXTENSIONS=1 pip install --no-cache-dir --no-deps --prefer-binary --target /opt/deps \
        -r /tmp/requirements.txt

FROM cgr.dev/chainguard/python:latest@sha256:f33049a06b10d6bd729e08a181094774ca5e9c7b0cf1bbe674aa977cd5258daa
LABEL maintainer="Hans Christian Winther-Sørensen <docker@wsh.no>"
COPY --from=deps /opt/deps /opt/deps
COPY start.py /srv/start.py

# Defaults — override via env / k8s ConfigMap + Secret. RESOURCE_PATH may be a filesystem dir
# (sidecar sharing readsb's JSON directory) or an http URL to a /data endpoint.
# LAT/LON refine range calculations; unset falls back to receiver.json's position.
ENV PYTHONPATH="/opt/deps" \
    PYTHONDONTWRITEBYTECODE="1" \
    RESOURCE_PATH="/run/readsb" \
    EXPORTER_PORT="9105" \
    LAT="" \
    LON=""

USER 65532:65532
EXPOSE 9105
ENTRYPOINT ["/usr/bin/python3", "/srv/start.py"]
