#!/data/data/com.termux/files/usr/bin/bash
# Run this on your device to collect pre-built wheels into the wheels/ directory

set -e

R='\033[0;31m'
G='\033[0;32m'
Y='\033[0;33m'
C='\033[0;36m'
NC='\033[0m'

WHEELS_DIR="$(dirname "$0")/wheels"
mkdir -p "$WHEELS_DIR"

echo -e "${C}Collecting pre-built wheels from pip cache...${NC}"
echo ""

CACHE_DIR="$HOME/.cache/pip/wheels"

TARGETS=(
  "psutil"
  "pyyaml"
  "jiter"
  "pydantic_core"
  "cryptography"
  "ruamel_yaml_clib"
  "cffi"
  "maturin"
  "markupsafe"
)

for pkg in "${TARGETS[@]}"; do
  WHEEL=$(find "$CACHE_DIR" -iname "${pkg}*.whl" 2>/dev/null | head -1)
  if [ -n "$WHEEL" ]; then
    cp "$WHEEL" "$WHEELS_DIR/"
    echo -e "${G}  ✓  Collected: $(basename $WHEEL)${NC}"
  else
    echo -e "${Y}  ⚠  Not found in cache: $pkg${NC}"
  fi
done

echo ""
echo -e "${G}Wheels collected to: $WHEELS_DIR${NC}"
echo ""
ls -lh "$WHEELS_DIR"
