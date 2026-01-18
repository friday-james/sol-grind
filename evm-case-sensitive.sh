#!/bin/bash
# Case-sensitive Ethereum vanity address generator (CPU)
# Can run for hours - will find it eventually

PATTERN="${1:-1ead01}"

echo "=== Case-Sensitive EVM Vanity Generator ==="
echo "Pattern: 0x$PATTERN (exact case)"
echo "This may take several hours on CPU"
echo ""
echo "Running in background..."
echo "Output will be saved to: ~/evm-vanity-result.txt"
echo ""

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Run in background with nohup
nohup python3 "$SCRIPT_DIR/evm-vanity-fast.py" "$PATTERN" prefix true > ~/evm-vanity-result.txt 2>&1 &

PID=$!
echo "Process ID: $PID"
echo ""
echo "To check progress:"
echo "  tail -f ~/evm-vanity-result.txt"
echo ""
echo "To stop:"
echo "  kill $PID"
echo ""
echo "The private key will be saved to ~/evm-vanity-result.txt when found."
