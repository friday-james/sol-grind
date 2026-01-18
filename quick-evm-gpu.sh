#!/bin/bash
# Quick GPU Ethereum vanity address generator
# Usage: ./quick-evm-gpu.sh 1ead01

PATTERN="${1:-1ead01}"

echo "=== Quick GPU EVM Vanity (Case-Sensitive) ==="
echo "Pattern: 0x$PATTERN"
echo ""

# Check if VanitySearch is built
if [ ! -f "/tmp/VanitySearch/VanitySearch" ]; then
    echo "[*] VanitySearch not found. Building (one-time, ~2 min)..."
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    sudo "$SCRIPT_DIR/build-vanitysearch.sh"
    echo ""
fi

cd /tmp/VanitySearch

# Run GPU search (case-sensitive by default in VanitySearch)
echo "[*] Starting GPU search..."
./VanitySearch -gpu "$PATTERN"

echo ""
echo "⚠️  SAVE THE PRIVATE KEY!"
