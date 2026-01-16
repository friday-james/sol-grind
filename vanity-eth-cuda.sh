#!/bin/bash
set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <pattern> [case-sensitive]"
    echo ""
    echo "Examples:"
    echo "  $0 1ead             # Case-insensitive: 0x1ead, 0x1EAD, etc."
    echo "  $0 1ead true        # Case-sensitive: exactly 0x1ead"
    echo ""
    exit 1
fi

PATTERN="$1"
CASE_SENSITIVE="${2:-false}"

echo "=== Ethereum GPU Vanity Generator ==="
echo "Pattern: 0x$PATTERN"
echo "Case-sensitive: $CASE_SENSITIVE"
echo ""

# Build eth-vanity-cuda if needed
if [ ! -f "/tmp/eth-vanity-cuda/eth-vanity" ]; then
    echo "[*] Building eth-vanity-cuda (first time, ~1 minute)..."
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    "$SCRIPT_DIR/build-eth-vanity-cuda.sh"
fi

cd /tmp/eth-vanity-cuda

echo ""
echo "=== Starting GPU Search ==="
echo "Pattern: 0x$PATTERN"
echo "Press Ctrl+C to stop"
echo ""

# Run search
if [ "$CASE_SENSITIVE" = "true" ]; then
    ./eth-vanity -p "$PATTERN" -c
else
    ./eth-vanity -p "$PATTERN"
fi

echo ""
echo "=== Done! ==="
echo "⚠️  SAVE THE PRIVATE KEY shown above!"
