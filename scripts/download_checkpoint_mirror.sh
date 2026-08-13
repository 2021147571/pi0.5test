#!/usr/bin/env bash
set -euo pipefail

export PATH="${HOME}/.local/bin:${PATH}"

DATA_ROOT="${PI05_DATA_ROOT:-/root/autodl-tmp/pi05-libero}"
BASE="${PI05_CHECKPOINT_MIRROR:-https://hf-mirror.com/xuych/pi0.5weight/resolve/main/pi05_libero}"
CHECKPOINT_ROOT="${DATA_ROOT}/cache/openpi-assets/checkpoints"
DEST="${CHECKPOINT_ROOT}/pi05_libero.partial"
FINAL="${CHECKPOINT_ROOT}/pi05_libero"

if ! command -v aria2c >/dev/null 2>&1; then
  echo "aria2c is required (Ubuntu: apt-get install -y aria2)." >&2
  exit 1
fi
if [[ -e "${FINAL}" ]]; then
  echo "Checkpoint already exists: ${FINAL}"
  exit 0
fi

mkdir -p "${DEST}/assets/physical-intelligence/libero"   "${DEST}/params/array_metadatas"   "${DEST}/params/d"   "${DEST}/params/ocdbt.process_0/d"

download() {
  local relative="$1"
  local expected="$2"
  local expected_sha256="${3:-}"
  local output="${DEST}/${relative}"
  mkdir -p "$(dirname "${output}")"
  aria2c --allow-overwrite=true --auto-file-renaming=false --continue=true     --max-connection-per-server=16 --min-split-size=8M --split=16     --file-allocation=none --summary-interval=10     --dir="$(dirname "${output}")" --out="$(basename "${output}")"     "${BASE}/${relative}"
  test "$(stat -c %s "${output}")" = "${expected}"
  if [[ -n "${expected_sha256}" ]]; then
    printf '%s  %s\n' "${expected_sha256}" "${output}" | sha256sum --check --status
  fi
  printf 'verified %s (%s bytes)\n' "${relative}" "${expected}"
}

download "assets/physical-intelligence/libero/norm_stats.json" 1914
download "params/_METADATA" 23493
download "params/_sharding" 17952
download "params/array_metadatas/process_0" 9062
download "params/d/98a77a52a8eb845ae4830eb7fe983979" 42307
download "params/manifest.ocdbt" 120
download "params/ocdbt.process_0/manifest.ocdbt" 322
download "params/ocdbt.process_0/d/2b6985f48e9da86f68627a7608c5bc25" 1077
download "params/ocdbt.process_0/d/bc613ff288a162563e622d01bb60622a" 217
download "params/ocdbt.process_0/d/bda87d9791f23df771cd2d15293780cc" 2926522

pids=()
download "params/ocdbt.process_0/d/0eaaecefaa9720d30a32cc56e65fd345" 2449323387 0d4412552d4a69fba953f824a60d005ee7559822a9c1c16684906c7f0801b848 & pids+=($!)
download "params/ocdbt.process_0/d/155391c1cbf93a1be16266de052e5b48" 2307885530 ad09cf4b2cacc0628c713afbb1ee9decfd36e295fdacae111c1e0c5eeeb6cc00 & pids+=($!)
download "params/ocdbt.process_0/d/475fab3ee8821662585a8cde3eb32e22" 2150232827 624a529b0b5f07bf535e07eba4f823e47fdde66a3d0b38295a35ac9d60cfcf0f & pids+=($!)
download "params/ocdbt.process_0/d/6c54da5a6f62c20a09c0f3f8c3329e00" 1608436908 1a5f80ef1aeaa82e70cca883c4d95da65bd410c8da19729d4814317533ba11f5 & pids+=($!)
download "params/ocdbt.process_0/d/896bf93c5cf2e8ddd274a6ea0a2feec0" 2240080987 c92342da7593219debce6133f148f3c24ece184ff53f9f4bac800c09fcc6dc1a & pids+=($!)
download "params/ocdbt.process_0/d/efbb46173882cb35ed41ffe0c2db8a5e" 1680102856 6e62d35e0689dc12779d0b2e65304823d6787fdd4ccd754c9ebd059fdc4b6765 & pids+=($!)

failed=0
for pid in "${pids[@]}"; do
  wait "${pid}" || failed=1
done
test "${failed}" -eq 0
test -z "$(find "${DEST}" -type f -name '*.aria2' -print -quit)"
total_bytes="$(find "${DEST}" -type f -print0 | xargs -0 du -b -c | tail -1 | cut -f1)"
test "${total_bytes}" = "12439085481"

mv "${DEST}" "${FINAL}"
echo "Checkpoint ready: ${FINAL} (${total_bytes} bytes)"
