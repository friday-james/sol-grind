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

# Install dependencies
echo "[*] Installing dependencies..."
sudo apt-get update -qq
sudo apt-get install -y -qq git build-essential libgmp3-dev

# Clone VanitySearch (GPU-accelerated)
cd /tmp
if [ ! -d "VanitySearch" ]; then
    echo "[*] Cloning VanitySearch..."
    git clone https://github.com/JeanLucPons/VanitySearch.git
fi

cd VanitySearch

# Build
if [ ! -f "VanitySearch" ]; then
    echo "[*] Building VanitySearch..."
    if [ "$USE_GPU" = true ]; then
        make gpu=1 CCAP=75
    else
        make
    fi
fi

echo ""
echo "=== Starting Search ==="
echo "Pattern: $PATTERN ($POSITION)"
echo "Press Ctrl+C to stop"
echo ""

# Run search
if [ "$POSITION" = "suffix" ]; then
    # For suffix, we need to use -s flag
    ./VanitySearch -s "$PATTERN" -gpu
else
    # For prefix
    if [ "$USE_GPU" = true ]; then
        ./VanitySearch -gpu "$PATTERN"
    else
        ./VanitySearch "$PATTERN"
    fi
fi

echo ""
echo "=== Search complete! ==="
echo "Check output above for private key and address"
