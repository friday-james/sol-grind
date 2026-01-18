#!/bin/bash
# Case-sensitive Ethereum vanity address generator (CPU)
# Can run for hours - will find it eventually

PATTERN="${1:-1ead01}"

echo "=== Case-Sensitive EVM Vanity Generator ==="
echo "Pattern: 0x$PATTERN (exact case)"
echo "This may take several hours on CPU"
echo "Press Ctrl+C to stop"
echo ""

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Run in foreground
python3 "$SCRIPT_DIR/evm-vanity-fast.py" "$PATTERN" prefix true
