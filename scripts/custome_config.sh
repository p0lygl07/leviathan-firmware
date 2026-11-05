#!/bin/bash
# Runs from ./project (sourced by the workflow).

# --- upstream FriendlyWrt tweaks (keep) ---
sed -i -e '/CONFIG_MAKE_TOOLCHAIN=y/d' configs/rockchip/01-nanopi
sed -i -e 's/CONFIG_IB=y/# CONFIG_IB is not set/g' configs/rockchip/01-nanopi
sed -i -e 's/CONFIG_SDK=y/# CONFIG_SDK is not set/g' configs/rockchip/01-nanopi

# --- Leviathan package selection ---
cp ../leviathan/config/99-leviathan configs/rockchip/99-leviathan
echo "[leviathan] added configs/rockchip/99-leviathan"
