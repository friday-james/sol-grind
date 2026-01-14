#!/bin/bash
set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <pattern> [prefix|suffix] [case-sensitive]"
    echo ""
    echo "Examples:"
    echo "  $0 1ead                    # Case-insensitive prefix: 0x1ead..."
    echo "  $0 1ead prefix true        # Case-sensitive: 0x1ead... (exact case)"
    echo "  $0 cafe prefix false       # Case-insensitive: 0xcafe, 0xCaFe, etc."
    echo ""
    exit 1
fi

PATTERN="$1"
MODE="${2:-prefix}"
CASE_SENSITIVE="${3:-false}"

echo "=== EVM Vanity Address Generator (GPU) ==="
echo "Pattern: $PATTERN"
echo "Case-sensitive: $CASE_SENSITIVE"
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
SEARCH_ARGS="-gpu"

# Add case-insensitive flag if needed
if [ "$CASE_SENSITIVE" = "false" ]; then
    SEARCH_ARGS="$SEARCH_ARGS -i"
fi

if [ "$MODE" = "suffix" ]; then
    # Suffix mode (slow)
    ./VanitySearch $SEARCH_ARGS -s "$PATTERN"
else
    # Prefix mode (fast)
    ./VanitySearch $SEARCH_ARGS "$PATTERN"
fi

echo ""
echo "=== Done! ==="
echo "⚠️  SAVE THE PRIVATE KEY shown above!"
