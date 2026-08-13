#!/usr/bin/env bash
set -euo pipefail

SUITE="${1:-libero_goal}"
TRIALS="${2:-1}"
DATA_ROOT="${PI05_DATA_ROOT:-/root/autodl-tmp/pi05-libero}"
OPENPI_DIR="${DATA_ROOT}/openpi"
RESULT_ROOT="${PI05_RESULT_ROOT:-$(pwd)/results/raw}"
OPENPI_COMMIT="15a9616a00943ada6c20a0f158e3adb39df2ccac"

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
export SERVER_ARGS="--env LIBERO"
export CLIENT_ARGS="--args.task-suite-name ${SUITE} --args.num-trials-per-task ${TRIALS}"

echo "Suite: ${SUITE}"
echo "Trials per task: ${TRIALS}"
echo "Checkpoint: gs://openpi-assets/checkpoints/pi05_libero"
echo "Log: ${LOG_FILE}"

cd "${OPENPI_DIR}"
docker compose -f examples/libero/compose.yml up --build 2>&1 | tee "${LOG_FILE}"

