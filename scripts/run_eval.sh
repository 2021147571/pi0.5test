#!/usr/bin/env bash
set -euo pipefail

SUITE="${1:-libero_goal}"
TRIALS="${2:-1}"
DATA_ROOT="${PI05_DATA_ROOT:-/root/autodl-tmp/pi05-libero}"
OPENPI_DIR="${DATA_ROOT}/openpi"
RESULT_ROOT="${PI05_RESULT_ROOT:-$(pwd)/results/raw}"
OPENPI_COMMIT="15a9616a00943ada6c20a0f158e3adb39df2ccac"
SERVER_PORT="${PI05_SERVER_PORT:-8000}"
SERVER_START_TIMEOUT="${PI05_SERVER_START_TIMEOUT:-3600}"

if [[ ! -d "${OPENPI_DIR}/.git" ]]; then
  echo "Run scripts/install.sh first." >&2
  exit 1
fi
if [[ "$(git -C "${OPENPI_DIR}" rev-parse HEAD)" != "${OPENPI_COMMIT}" ]]; then
  echo "openpi commit mismatch; rerun scripts/install.sh" >&2
  exit 1
fi
if ! [[ "${TRIALS}" =~ ^[1-9][0-9]*$ ]]; then
  echo "TRIALS must be a positive integer" >&2
  exit 1
fi

mkdir -p "${RESULT_ROOT}"
LOG_FILE="${RESULT_ROOT}/eval-${SUITE}-trials${TRIALS}-$(date +%Y%m%d-%H%M%S).log"

export OPENPI_DATA_HOME="${DATA_ROOT}/cache"
export MUJOCO_GL="${MUJOCO_GL:-egl}"
export LIBERO_CONFIG_PATH="${DATA_ROOT}/libero-config"
export PYOPENGL_PLATFORM="egl"
export MUJOCO_EGL_DEVICE_ID="0"
echo "Suite: ${SUITE}"
echo "Trials per task: ${TRIALS}"
echo "Checkpoint: gs://openpi-assets/checkpoints/pi05_libero"
echo "Log: ${LOG_FILE}"

cd "${OPENPI_DIR}"
SERVER_LOG="${RESULT_ROOT}/server-${SUITE}-trials${TRIALS}-$(date +%Y%m%d-%H%M%S).log"

cleanup() {
  if [[ -n "${SERVER_PID:-}" ]] && kill -0 "${SERVER_PID}" 2>/dev/null; then
    kill "${SERVER_PID}" 2>/dev/null || true
    wait "${SERVER_PID}" 2>/dev/null || true
  fi
}
trap cleanup EXIT INT TERM

OPENPI_DATA_HOME="${OPENPI_DATA_HOME}" uv run scripts/serve_policy.py --env LIBERO --port "${SERVER_PORT}"   >"${SERVER_LOG}" 2>&1 &
SERVER_PID=$!

server_ready=0
for _ in $(seq 1 "${SERVER_START_TIMEOUT}"); do
  if curl --silent --show-error --fail "http://127.0.0.1:${SERVER_PORT}/healthz" >/dev/null 2>&1; then
    server_ready=1
    break
  fi
  if ! kill -0 "${SERVER_PID}" 2>/dev/null; then
    echo "Policy server stopped unexpectedly. See ${SERVER_LOG}" >&2
    tail -n 80 "${SERVER_LOG}" >&2 || true
    exit 1
  fi
  sleep 1
done

if [[ "${server_ready}" -ne 1 ]]; then
  echo "Policy server did not become healthy within ${SERVER_START_TIMEOUT}s. See ${SERVER_LOG}" >&2
  tail -n 80 "${SERVER_LOG}" >&2 || true
  exit 1
fi

export PYTHONPATH="${OPENPI_DIR}/third_party/libero${PYTHONPATH:+:${PYTHONPATH}}"
export MUJOCO_GL
"${OPENPI_DIR}/examples/libero/.venv/bin/python" examples/libero/main.py   --host 127.0.0.1   --port "${SERVER_PORT}"   --task-suite-name "${SUITE}"   --num-trials-per-task "${TRIALS}"   --video-out-path "${RESULT_ROOT}/videos-${SUITE}-trials${TRIALS}"   2>&1 | tee "${LOG_FILE}"
