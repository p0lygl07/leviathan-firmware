#!/bin/bash
# Runs from ./project. Forces kernel options Leviathan depends on.

CONFIGS=(
  "CONFIG_NET_ACT_CT=m"
  "CONFIG_NET_ACT_CTINFO=m"
  # AR9271 USB radio (monitor / injection)
  "CONFIG_ATH9K=m"
  "CONFIG_ATH9K_HTC=m"
)

source .current_config.mk
KCFG=kernel/arch/arm64/configs/$(awk '{print $1}' <<< "$TARGET_KERNEL_CONFIG")

for CFG in "${CONFIGS[@]}"; do
  KEY=${CFG%%=*}
  if grep -q "^#\?\s*${KEY}[= ]" "${KCFG}"; then
    sed -i "s@^#\?\s*${KEY}[= ].*@${CFG}@g" "${KCFG}"
  else
    echo "$CFG" >> "${KCFG}"
  fi
done
echo "[leviathan] kernel config patched: ${KCFG}"
