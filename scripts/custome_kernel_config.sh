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
# Fix: this 6.1 kernel's bitfield.h predates FIELD_PREP_CONST, but the
# bundled rtw88 driver uses it -> -Werror=implicit-function-declaration
# breaks `build.sh kernel`. Define it if missing (constant-expression
# safe; __bf_shf is already provided in the same header).
# ---------------------------------------------------------------------
BF=kernel/include/linux/bitfield.h
if [ -f "$BF" ] && ! grep -q "FIELD_PREP_CONST" "$BF"; then
cat >> "$BF" <<'BFEOF'

#ifndef FIELD_PREP_CONST
#define FIELD_PREP_CONST(_mask, _val) \
	(((typeof(_mask))(_val) << __bf_shf(_mask)) & (_mask))
#endif
BFEOF
echo "[leviathan] patched FIELD_PREP_CONST into ${BF}"
fi
