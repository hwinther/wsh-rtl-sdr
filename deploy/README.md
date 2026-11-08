# deploy/

Kubernetes workload manifests for the edge-sdr cluster. On every release, the `manifests` job in
`.github/workflows/release.yml` runs the `manifests` action from hwinther/reusable-workflows. The
action:

1. renders each directory below, with every image pinned to `tag@digest` (the images that release
   just built);
2. validates the output with kubeconform;
3. pushes it as one OCI artifact to `ghcr.io/hwinther/wsh-rtl-sdr/manifests:<version>`;
4. signs it with cosign (keyless, identity `release.yml@refs/tags/v<version>`).

Nothing is published unless all nine release images were built, scanned, signed and pushed for both
`linux/amd64` and `linux/arm64`, so the artifact never references a tag that doesn't exist yet.

The artifact holds one render per namespace. A Flux Kustomization picks one with its `path`:

| Path | Rendered from | Workloads | Namespace (in proxmox) |
|---|---|---|---|
| `./adsb` | `deploy/adsb` | readsb (+ dump1090-exporter), tar1090, piaware, fr24, adsbexchange, opensky, adsb-mqtt | `adsb-edge-sdr` |
| `./ais-catcher` | `deploy/ais-catcher` | AIS-catcher | `ais-catcher-edge-sdr` |
| `./sdr-debug` | `deploy/sdr-debug` | sdr-toolbox debug CronJobs (suspended, run on demand) | `sdr-debug-edge-sdr` |

On pull requests, `manifest-diff.yml` posts the rendered diff against the base branch as a PR
comment. Don't commit rendered output.

The cluster repo (hwinther/proxmox, `clusters/edge-sdr/apps/<namespace>/`) consumes the artifact
through a Flux `OCIRepository` and one `Kustomization` per path. It provides everything that isn't
in here:

- the namespaces (via `targetNamespace`; the manifests carry no `metadata.namespace`);
- the station config ConfigMaps (`adsb-env`, `ais-catcher-env`), the Secrets and the Ingresses;
- the Kyverno exceptions for the hostPath mounts;
- the variable values below (via `postBuild.substitute`).

## Contract

### Variables

CI fails if the rendered output contains a variable without a default that isn't listed here. Flux
would otherwise substitute an empty string.

| Variable | Default | Render | Used for |
|---|---|---|---|
| `MQTT_HOST` | (required) | adsb | Broker that adsb-mqtt publishes aircraft to, e.g. the mosquitto LoadBalancer VIP `10.20.13.100` |
| `AIS_CATCHER_URL` | (required) | adsb | `aiscatcher_server` in tar1090's `config.js`: the public AIS-catcher URL whose vessels tar1090 overlays, e.g. `https://ais.edge-sdr.wsh.no` |

Shell scripts in these manifests must use `$VAR`, never `${VAR}`: Flux's `postBuild.substitute`
would replace a braced variable cluster-side.

### ConfigMaps, Secrets and storage

In the target namespace:

- **adsb:** ConfigMap `adsb-env` (station baseline, `envFrom`) and Secret `adsb-secret` (feeder keys,
  exact position, `piaware.conf`, `opensky.conf`, `upintheair.json`; see the proxmox README for the
  keys). The decoder output is a node-local hostPath, `/run/k8s-edge-sdr/readsb`, shared by readsb,
  tar1090 and adsb-mqtt.
- **ais-catcher:** ConfigMap `ais-catcher-env` and Secret `ais-catcher-secret`.
- **sdr-debug:** nothing.

### Cluster requirements

- Raspberry Pi workers with `role=sdr-edge`, the taint `node-type=edge-sdr:NoSchedule`, and
  `edge-sdr/adsb-antenna=true` on the Pi with the ADS-B antenna.
- The SDR device plugin, which provides the extended resources `sdr.wsh.no/rtlsdr-adsb` and
  `sdr.wsh.no/rtlsdr-ais`, and containerd's `device_ownership_from_security_context` so the decoders
  open their dongle as uid 65532.
