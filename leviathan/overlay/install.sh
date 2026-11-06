#!/bin/bash
# Called by FriendlyELEC's build.sh with the rootfs dir as $1
# (via FRIENDLYWRT_FILES+=(leviathan/overlay)).
set -eu
ROOTFS_DIR=$1
HERE=$(cd "$(dirname "$0")" && pwd)

rsync -a --no-o --no-g "${HERE}/files/" "${ROOTFS_DIR}/"

chmod 0755 "${ROOTFS_DIR}/etc/uci-defaults/zz-leviathan"
for s in leviathan-uplink leviathan-mon leviathan-scan leviathan-handshake leviathan-pmkid leviathan-node; do
	chmod 0755 "${ROOTFS_DIR}/usr/sbin/${s}"
done

echo "${LEVIATHAN_VERSION:-dev}" > "${ROOTFS_DIR}/etc/leviathan_version"
sed -i "s/__LEV_VER__/${LEVIATHAN_VERSION:-dev}/" "${ROOTFS_DIR}/etc/banner"
echo "[leviathan] overlay applied (${LEVIATHAN_VERSION:-dev})"
