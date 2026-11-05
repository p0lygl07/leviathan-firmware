#!/bin/bash
# build-local.sh — build the Leviathan image on a local Ubuntu 22.04 box
# (or WSL2 Ubuntu). Mirrors the GitHub Actions workflow. Needs ~30GB free
# and a few hours. Run from the repo root:  bash scripts/build-local.sh v0.1.0
set -euo pipefail

LEV_VER="${1:-dev}"
FWRT_VER="25.12"
CPU="rk3528"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

command -v repo >/dev/null || {
  git clone https://github.com/friendlyarm/repo /tmp/fa-repo
  sudo cp /tmp/fa-repo/repo /usr/bin/ && sudo chmod +x /usr/bin/repo
}

mkdir -p build && cd build

# --- source (image manifest: kernel/uboot/device/friendlywrt) ---
if [ ! -d project ]; then
  mkdir project && cd project
  repo init --depth=1 -u https://github.com/friendlyarm/friendlywrt_manifests \
    -b "master-v${FWRT_VER}" -m "${CPU}.xml" \
    --repo-url=https://github.com/friendlyarm/repo --no-clone-bundle
  repo sync -c --no-clone-bundle
  cd ..
fi

cp -r "${REPO_ROOT}/leviathan" project/leviathan

cd project
# package selection
source "${REPO_ROOT}/scripts/custome_config.sh"

# config + overlay
DIST_DIR="friendlywrt${FWRT_VER%%.*}"
IMG_FILE="${CPU}-leviathan-${LEV_VER}.img"
cat > .current_config.mk <<EOL
. device/friendlyelec/${CPU}/base.mk
TARGET_IMAGE_DIRNAME=${DIST_DIR}
TARGET_FRIENDLYWRT_CONFIG=rockchip
TARGET_SD_RAW_FILENAME=${IMG_FILE}
FRIENDLYWRT_FILES+=(leviathan/overlay)
EOL

# kernel options
source "${REPO_ROOT}/scripts/custome_kernel_config.sh"

export LEVIATHAN_VERSION="${LEV_VER}"
./build.sh

OUT="out/${IMG_FILE}"
[ -f "$OUT" ] || OUT=$(find out -name "${IMG_FILE}" | head -1)
gzip -kf "$OUT"
echo
echo "=== done ==="
echo "image: build/project/${OUT}.gz"
sha256sum "${OUT}.gz"
