#!/bin/bash
set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <prefix|suffix> [position]"
    echo ""
    echo "Examples:"
    echo "  $0 dead           # Prefix: 0xdead..."
    echo "  $0 cafe prefix    # Prefix: 0xcafe..."
    echo "  $0 beef suffix    # Suffix: ...beef"
    echo ""
    echo "Note: EVM addresses are hex (0-9, a-f only)"
    exit 1
fi

PATTERN="$1"
POSITION="${2:-prefix}"

echo "=== EVM Vanity Address Generator ==="
echo "Pattern: $PATTERN"
echo "Position: $POSITION"
echo ""

# Check GPU
if nvidia-smi &> /dev/null; then
    echo "[*] GPU detected:"
    nvidia-smi --query-gpu=name --format=csv,noheader
    echo ""
    USE_GPU=true
else
    echo "[*] No GPU detected, using CPU mode"
    USE_GPU=false
fi

# Install Python dependencies
echo "[*] Installing Python dependencies..."
sudo apt-get update -qq
sudo apt-get install -y -qq python3-pip
pip3 install --break-system-packages eth-keys eth-utils "eth-hash[pycryptodome]" 2>&1 | grep -E "Successfully installed|already satisfied" || true

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Run Python vanity generator
python3 "$SCRIPT_DIR/evm-vanity-simple.py" "$PATTERN" "$POSITION"
