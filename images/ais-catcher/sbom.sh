#!/bin/sh
# Writes a CycloneDX SBOM (JSON, to stdout) for a static binary built in an xx/Alpine stage: the
# application at its git commit, plus each named Alpine package from the TARGET sysroot's apk
# database (the archives it was linked against). The apk components carry Syft-style purls (with
# the upstream and distro qualifiers), so Grype matches them against Alpine's security data, and
# Kubescape does too once kubevuln's scanEmbeddedSBOMs is on.
#
# Usage: sbom.sh <app-name> <git-commit> <git-url> <apk-package>...
set -eu

app=$1 ref=$2 url=$3
shift 3

db="$(xx-info sysroot)lib/apk/db/installed"
distro="alpine-$(cat /etc/alpine-release)"

components=""
for pkg in "$@"; do
    # A record per package, blank-line separated: P=name, V=version, A=arch, o=origin.
    line=$(awk -v want="$pkg" '
        /^P:/ { p = substr($0, 3) } /^V:/ { v = substr($0, 3) }
        /^A:/ { a = substr($0, 3) } /^o:/ { o = substr($0, 3) }
        /^$/  { if (p == want) { print v " " a " " o; exit } p = v = a = o = "" }
        END   { if (p == want) print v " " a " " o }' "$db")
    [ -n "$line" ] || { echo "sbom.sh: $pkg is not installed in $db" >&2; exit 1; }
    set -- $line
    version=$1 arch=$2 origin=$3
    # purl names percent-encode "+" (libstdc++).
    purl="pkg:apk/alpine/$(echo "$pkg" | sed 's/+/%2B/g')@${version}?arch=${arch}&upstream=${origin}&distro=${distro}"
    components="${components}${components:+,}
    {\"type\":\"library\",\"bom-ref\":\"${purl}\",\"name\":\"${pkg}\",\"version\":\"${version}\",\"purl\":\"${purl}\"}"
done

cat <<EOF
{
  "bomFormat": "CycloneDX",
  "specVersion": "1.5",
  "version": 1,
  "metadata": {
    "component": {"type":"application","bom-ref":"${app}","name":"${app}","version":"${ref}",
      "externalReferences":[{"type":"vcs","url":"${url}"}]}
  },
  "components": [${components}
  ]
}
EOF
