#!/bin/bash
set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <pattern> [prefix|suffix]"
    echo ""
    echo "Examples:"
    echo "  $0 1ead           # Prefix: 0x1ead..."
    echo "  $0 cafe prefix    # Prefix: 0xcafe..."
    echo ""
    exit 1
fi

PATTERN="$1"
MODE="${2:-prefix}"

echo "=== EVM Vanity Address Generator (GPU) ==="
echo "Pattern: $PATTERN"
echo ""

# Build VanitySearch if needed
if [ ! -f "/tmp/VanitySearch/VanitySearch" ]; then
    echo "[*] Building VanitySearch (first time setup, ~2 minutes)..."
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    "$SCRIPT_DIR/build-vanitysearch.sh"
fi

cd /tmp/VanitySearch

# Check GPU
echo "[*] Checking GPU..."
./VanitySearch -gpu -check

echo ""
echo "=== Starting GPU Search ==="
echo "Pattern: 0x$PATTERN"
echo "Press Ctrl+C to stop"
echo ""

# Run search
if [ "$MODE" = "suffix" ]; then
    # Suffix mode (slow)
    ./VanitySearch -gpu -s "$PATTERN"
else
    # Prefix mode (fast)
    ./VanitySearch -gpu "$PATTERN"
fi

echo ""
echo "=== Done! ==="
echo "⚠️  SAVE THE PRIVATE KEY shown above!"
