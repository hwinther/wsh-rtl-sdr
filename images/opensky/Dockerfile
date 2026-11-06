# syntax=docker/dockerfile:1
#
# opensky: the OpenSky Network feeder (openskyd-dump1090 from openskynetwork/opensky-sensor) built
# from pinned upstream source as one static (musl) binary on distroless: no shell, no package
# manager. It reads Beast from dump1090-fa:30005 and feeds OpenSky.
#
# Cross-compiled with tonistiigi/xx (clang for the target, musl sysroot from Alpine), so the arm64
# build runs at native speed on an amd64 runner instead of under QEMU. Only the dump1090 feeder is
# built (no Radarcape/Trimble daemons, no C++ library).
#
# Configuration: openskyd reads every *.conf in /etc/openskyd/conf.d (mounted from the Deployment's
# Secret: [GPS] position, [IDENT] username, [DEVICE] type and serial, [INPUT] host/port) and in
# /var/lib/openskyd/conf.d, where it saves a serial number OpenSky assigns. Both directories must
# exist; /var/lib/openskyd must be writable (an emptyDir).
#
# Updates: Dependabot bumps the alpine, xx and distroless digests. Upstream has not moved since
# 2021-12 (2.1.7); a new commit is a manual OPENSKY_REF bump.

ARG OPENSKY_REF=51b95facb5310024a3812ab07bab4dea92d6fef7

FROM --platform=$BUILDPLATFORM tonistiigi/xx:1.10.0@sha256:40fe21f44bb8cddf1eb1226db190d0a984118f62ee02a91b77d99448d28264a6 AS xx

FROM --platform=$BUILDPLATFORM alpine:3.24@sha256:be2656061b536c1883c4034790e21d0a09c5aaaf51968b89368a3c0371ea2c9a AS build
COPY --from=xx / /
# llvm: target-independent ar/ranlib for the static libraries (autoconf finds no ar for a cross host).
RUN apk add --no-cache clang lld llvm make git pkgconf autoconf autoconf-archive automake libtool
ARG TARGETPLATFORM
# configure checks for a working C++ compiler even though only C is built, hence g++/libstdc++.
RUN xx-apk add --no-cache musl-dev gcc g++ linux-headers

ARG OPENSKY_REF
ADD --keep-git-dir=true https://github.com/openskynetwork/opensky-sensor.git#${OPENSKY_REF} /src

WORKDIR /src
# glibc assumptions that musl does not share: port/misc.h only knows glibc and Windows
# ("#error Unsupported system"), though it only picks the printf length modifier for size_t (musl
# has the C99 %zu/%zd); and some files use ssize_t and PATH_MAX without including sys/types.h and
# limits.h, which glibc's headers pull in by accident (hence the -include flags). gps.c and
# dump1090.c also include glibc's <error.h> without calling error(). libtool drops a plain -static
# when linking a program, so the final link gets -all-static.
RUN sed -i 's|^#error Unsupported system|#define PRI_SIZE_T "zu"\n#define PRI_SSIZE_T "zd"|' src/util/port/misc.h && \
    sed -i '/#include <error.h>/d' src/core/gps.c src/dump1090/dump1090.c && \
    autoreconf -fi && \
    ./configure --host="$(xx-clang --print-target-triple)" \
        CC=xx-clang CXX=xx-clang++ AR=llvm-ar RANLIB=llvm-ranlib \
        CFLAGS="-O2 -DNDEBUG -include sys/types.h -include limits.h" LDFLAGS="-static -s" \
        --prefix=/usr --sysconfdir=/etc/openskyd --localstatedir=/var/lib/openskyd \
        --enable-dump1090 --disable-dump1090-donated --disable-dump1090-kit \
        --disable-gp-library --without-systemd --without-pacman --without-check && \
    make -j"$(nproc)" -C src/util && \
    make -j"$(nproc)" -C src/core && \
    make -j"$(nproc)" -C src/dump1090 openskyd-dump1090 LDFLAGS="-all-static -s" && \
    xx-verify --static src/dump1090/openskyd-dump1090 && \
    mkdir -p /out/etc/openskyd/conf.d /out/var/lib/openskyd/conf.d

# A CycloneDX SBOM of what is compiled into the binary (only musl beside opensky itself), for Grype
# and Kubescape (scanEmbeddedSBOMs).
COPY --chmod=755 sbom.sh /usr/local/bin/sbom.sh
RUN sbom.sh opensky-sensor "$OPENSKY_REF" https://github.com/openskynetwork/opensky-sensor \
        musl > /src/opensky.cdx.json

FROM gcr.io/distroless/static-debian13:nonroot@sha256:25ac8f0c3b2334a9eb05452266bd4697864a8c8ef0ef71e5e6480d7f92868329
LABEL maintainer="Hans Christian Winther-Sørensen <docker@wsh.no>"
COPY --from=build --chown=65532:65532 /out/ /
COPY --from=build /src/src/dump1090/openskyd-dump1090 /usr/bin/openskyd-dump1090
COPY --from=build /src/opensky.cdx.json /usr/share/sbom/opensky.cdx.json
ENTRYPOINT ["/usr/bin/openskyd-dump1090"]
