#!/usr/bin/env bash
set -euo pipefail

OPENPI_COMMIT="15a9616a00943ada6c20a0f158e3adb39df2ccac"
DATA_ROOT="${PI05_DATA_ROOT:-/root/autodl-tmp/pi05-libero}"
OPENPI_DIR="${DATA_ROOT}/openpi"

mkdir -p "${DATA_ROOT}" "${DATA_ROOT}/cache" "${DATA_ROOT}/results"

if ! command -v git >/dev/null; then
  echo "git is required" >&2
  exit 1
fi
if ! command -v docker >/dev/null; then
  echo "Docker is required by the official recommended LIBERO workflow." >&2
  echo "Install Docker and NVIDIA Container Toolkit, then rerun this script." >&2
  exit 1
fi

if [[ ! -d "${OPENPI_DIR}/.git" ]]; then
  git clone --recurse-submodules https://github.com/Physical-Intelligence/openpi.git "${OPENPI_DIR}"
fi

git -C "${OPENPI_DIR}" fetch origin "${OPENPI_COMMIT}"
git -C "${OPENPI_DIR}" checkout --detach "${OPENPI_COMMIT}"
git -C "${OPENPI_DIR}" submodule update --init --recursive

ACTUAL_COMMIT="$(git -C "${OPENPI_DIR}" rev-parse HEAD)"
test "${ACTUAL_COMMIT}" = "${OPENPI_COMMIT}"

cat <<EOF
Installation source is ready.
OPENPI_DIR=${OPENPI_DIR}
OPENPI_COMMIT=${ACTUAL_COMMIT}
OPENPI_DATA_HOME=${DATA_ROOT}/cache

Next:
  bash scripts/run_eval.sh libero_goal 1
EOF

