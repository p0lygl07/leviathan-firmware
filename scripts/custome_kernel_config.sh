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

# ---------------------------------------------------------------------
# Disable the bundled Realtek rtw88 driver. lwfinger/rtw88 is an
# inconsistent backport that will not compile against this 6.1 kernel,
# and Leviathan uses no Realtek radio — it runs the onboard AIC8800
# plus the AR9271 (ath9k_htc). The aic8800 build is a separate block
# and is left intact. We excise only the rtw88 block, and also skip the
# optional Realtek USB wifi drivers so none can break the kernel step.
# ---------------------------------------------------------------------
BK=scripts/sd-fuse/build-kernel.sh
if [ -f "$BK" ] && grep -q "build rtw_8822ce wifi driver" "$BK"; then
  perl -0pi -e 's/\n[ \t]*# build rtw_8822ce wifi driver.*?\n([ \t]*# build usb wifi driver)/\n$1/s' "$BK"
  echo "[leviathan] excised rtw88 block from ${BK}"
fi
export BUILD_THIRD_PARTY_DRIVER=0
echo "[leviathan] BUILD_THIRD_PARTY_DRIVER=0 (skip optional Realtek USB drivers)"
