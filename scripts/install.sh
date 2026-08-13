#!/usr/bin/env bash
set -euo pipefail

OPENPI_COMMIT="15a9616a00943ada6c20a0f158e3adb39df2ccac"
DATA_ROOT="${PI05_DATA_ROOT:-/root/autodl-tmp/pi05-libero}"
OPENPI_DIR="${DATA_ROOT}/openpi"

mkdir -p "${DATA_ROOT}" "${DATA_ROOT}/cache" "${DATA_ROOT}/results"

if command -v apt-get >/dev/null; then
  apt-get update
  DEBIAN_FRONTEND=noninteractive apt-get install -y \
    curl make g++ clang libosmesa6-dev libgl1-mesa-glx libegl1 \
    libglew-dev libglfw3-dev libgles2-mesa-dev libglib2.0-0 \
    libsm6 libxrender1 libxext6
fi

if ! command -v git >/dev/null; then
  echo "git is required" >&2
  exit 1
fi
if ! command -v uv >/dev/null; then
  curl -LsSf https://astral.sh/uv/install.sh | sh
  export PATH="${HOME}/.local/bin:${PATH}"
fi

if [[ ! -d "${OPENPI_DIR}/.git" ]]; then
  git clone --recurse-submodules https://github.com/Physical-Intelligence/openpi.git "${OPENPI_DIR}"
fi

git -C "${OPENPI_DIR}" fetch origin "${OPENPI_COMMIT}"
git -C "${OPENPI_DIR}" checkout --detach "${OPENPI_COMMIT}"
git -C "${OPENPI_DIR}" submodule update --init --recursive

ACTUAL_COMMIT="$(git -C "${OPENPI_DIR}" rev-parse HEAD)"
test "${ACTUAL_COMMIT}" = "${OPENPI_COMMIT}"

cd "${OPENPI_DIR}"
GIT_LFS_SKIP_SMUDGE=1 uv sync
GIT_LFS_SKIP_SMUDGE=1 uv pip install -e .

# LIBERO needs an older, isolated Python environment. Keeping it separate also
# prevents its MuJoCo / torch constraints from changing the policy server env.
uv venv --python 3.8 examples/libero/.venv
# shellcheck disable=SC1091
source examples/libero/.venv/bin/activate
uv pip sync examples/libero/requirements.txt third_party/libero/requirements.txt \
  --extra-index-url https://download.pytorch.org/whl/cu113 \
  --index-strategy=unsafe-best-match
uv pip install -e packages/openpi-client
uv pip install -e third_party/libero
deactivate

LIBERO_CONFIG_PATH="${DATA_ROOT}/libero-config"
mkdir -p "${LIBERO_CONFIG_PATH}"
cat >"${LIBERO_CONFIG_PATH}/config.yaml" <<EOF
benchmark_root: ${OPENPI_DIR}/third_party/libero/libero/libero
bddl_files: ${OPENPI_DIR}/third_party/libero/libero/libero/bddl_files
init_states: ${OPENPI_DIR}/third_party/libero/libero/libero/init_files
datasets: ${OPENPI_DIR}/third_party/libero/libero/datasets
assets: ${OPENPI_DIR}/third_party/libero/libero/libero/assets
EOF

cat <<EOF
Installation source is ready.
OPENPI_DIR=${OPENPI_DIR}
OPENPI_COMMIT=${ACTUAL_COMMIT}
OPENPI_DATA_HOME=${DATA_ROOT}/cache
LIBERO_CONFIG_PATH=${LIBERO_CONFIG_PATH}

Next:
  bash scripts/run_eval.sh libero_goal 1
EOF
