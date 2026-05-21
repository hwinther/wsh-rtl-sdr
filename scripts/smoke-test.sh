#!/usr/bin/env bash
# Build + smoke-test one (or all) wsh-rtl-sdr image(s) in isolation, with no
# RTL-SDR hardware, via docker-compose.test.yml. Guarantees teardown.
#
#   bash scripts/smoke-test.sh <image>|all
#
# Exit code is non-zero if any image fails its pass condition.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE_FILE="${REPO_ROOT}/docker-compose.test.yml"
COMPOSE=(docker compose -f "${COMPOSE_FILE}")

# image -> pass condition: "wait" (healthy/running via compose --wait) or
# "runonce" (container must exit 0).
declare -A MODE=(
  [dump1090-fa]=wait
  [ais-catcher]=wait
  [tar1090]=wait
  [piaware]=wait
  [fr24]=wait
  [adsbexchange]=wait
  [opensky]=wait
  [gsm-tools]=runonce
)
ALL_IMAGES=(dump1090-fa ais-catcher tar1090 piaware fr24 adsbexchange opensky gsm-tools)

WAIT_TIMEOUT="${SMOKE_WAIT_TIMEOUT:-300}"

teardown() {
  local img="$1"
  echo "--- teardown: ${img}"
  "${COMPOSE[@]}" --profile "${img}" down -v --remove-orphans >/dev/null 2>&1 || true
}

smoke_one() {
  local img="$1"
  local mode="${MODE[$img]:-}"
  if [[ -z "${mode}" ]]; then
    echo "FAIL ${img}: unknown image"
    return 1
  fi

  echo "=== smoke: ${img} (mode=${mode})"
  # Always tear down this profile on any exit path from this function.
  trap "teardown '${img}'" RETURN

  # Build first so a build failure (apt 404, disk full, etc.) is reported
  # distinctly from a runtime/health failure.
  if ! "${COMPOSE[@]}" --profile "${img}" build; then
    echo "FAIL ${img}: BUILD FAILED (see output above)"
    return 1
  fi

  if [[ "${mode}" == "runonce" ]]; then
    if ! "${COMPOSE[@]}" --profile "${img}" up -d; then
      echo "FAIL ${img}: up failed"
      return 1
    fi
    local cid
    cid="$("${COMPOSE[@]}" --profile "${img}" ps -aq "${img}")"
    if [[ -z "${cid}" ]]; then
      echo "FAIL ${img}: no container created"
      return 1
    fi
    # Wait for the one-shot container to exit.
    local waited=0
    while :; do
      local status
      status="$(docker inspect -f '{{.State.Status}}' "${cid}" 2>/dev/null || echo missing)"
      [[ "${status}" == "exited" || "${status}" == "missing" ]] && break
      (( waited >= 120 )) && { echo "FAIL ${img}: did not exit within 120s"; return 1; }
      sleep 2; waited=$((waited + 2))
    done
    local code
    code="$(docker inspect -f '{{.State.ExitCode}}' "${cid}" 2>/dev/null || echo 1)"
    if [[ "${code}" != "0" ]]; then
      echo "FAIL ${img}: binary-exists check exited ${code}"
      docker logs "${cid}" 2>&1 | tail -n 20
      return 1
    fi
    echo "PASS ${img}: binaries present"
    return 0
  fi

  # mode == wait: compose --wait blocks until every started container is
  # healthy (if it has a HEALTHCHECK) or running past its start period, and
  # returns non-zero if any becomes unhealthy or exits. That is the smoke
  # pass condition for the hub, the RF images and the network consumers.
  if ! "${COMPOSE[@]}" --profile "${img}" up -d --wait --wait-timeout "${WAIT_TIMEOUT}"; then
    echo "FAIL ${img}: did not become healthy/stable within ${WAIT_TIMEOUT}s"
    "${COMPOSE[@]}" --profile "${img}" ps
    "${COMPOSE[@]}" --profile "${img}" logs --tail 30 "${img}" 2>&1 || true
    return 1
  fi

  # Re-assert the target container itself is up and not crash-looping.
  local cid
  cid="$("${COMPOSE[@]}" --profile "${img}" ps -q "${img}")"
  if [[ -z "${cid}" ]]; then
    echo "FAIL ${img}: target container not found after up"
    return 1
  fi
  local running restarting health
  running="$(docker inspect -f '{{.State.Running}}' "${cid}")"
  restarting="$(docker inspect -f '{{.State.Restarting}}' "${cid}")"
  health="$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' "${cid}")"
  if [[ "${running}" != "true" || "${restarting}" == "true" ]]; then
    echo "FAIL ${img}: container not stably running (running=${running} restarting=${restarting})"
    docker logs "${cid}" 2>&1 | tail -n 30
    return 1
  fi
  if [[ "${health}" != "none" && "${health}" != "healthy" ]]; then
    echo "FAIL ${img}: healthcheck=${health}"
    docker logs "${cid}" 2>&1 | tail -n 30
    return 1
  fi
  echo "PASS ${img}: running (health=${health})"
  return 0
}

main() {
  local target="${1:-}"
  if [[ -z "${target}" ]]; then
    echo "usage: $0 <image>|all" >&2
    echo "images: ${ALL_IMAGES[*]}" >&2
    return 2
  fi

  local images=()
  if [[ "${target}" == "all" ]]; then
    images=("${ALL_IMAGES[@]}")
  else
    images=("${target}")
  fi

  local rc=0
  local summary=()
  for img in "${images[@]}"; do
    if smoke_one "${img}"; then
      summary+=("PASS ${img}")
    else
      summary+=("FAIL ${img}")
      rc=1
    fi
  done

  echo
  echo "===== smoke summary ====="
  printf '%s\n' "${summary[@]}"
  return "${rc}"
}

main "$@"
exit $?
