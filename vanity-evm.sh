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

# Install CUDA toolkit if GPU detected
if [ "$USE_GPU" = true ]; then
    if ! command -v nvcc &> /dev/null; then
        echo "[*] Installing CUDA toolkit..."
        sudo apt-get install -y -qq nvidia-cuda-toolkit
    fi

    # Create /usr/local/cuda symlink if it doesn't exist
    if [ ! -d "/usr/local/cuda" ] && [ -d "/usr/lib/cuda" ]; then
        sudo ln -sf /usr/lib/cuda /usr/local/cuda
    fi
fi

# Try profanity2 (better maintained, OpenCL-based)
cd /tmp
if [ ! -d "profanity2" ]; then
    echo "[*] Cloning profanity2..."
    git clone https://github.com/1inch/profanity2.git
fi

cd profanity2

# Build
if [ ! -f "profanity2.x64" ]; then
    echo "[*] Building profanity2..."

    # Install OpenCL if needed
    if [ "$USE_GPU" = true ]; then
        sudo apt-get install -y -qq ocl-icd-opencl-dev opencl-headers
    fi

    make 2>&1 | tee build.log

    if [ ! -f "profanity2.x64" ]; then
        echo "ERROR: Build failed. Check build.log"
        exit 1
    fi
fi

PROFANITY_BIN="./profanity2.x64"

echo ""
echo "=== Starting Search ==="
echo "Pattern: 0x$PATTERN ($POSITION)"
echo "Press Ctrl+C to stop"
echo ""

# Run search
if [ "$POSITION" = "suffix" ]; then
    echo "WARNING: Suffix search is very slow for EVM addresses!"
    echo "Using --matching with suffix pattern..."
    $PROFANITY_BIN --matching "^.*$PATTERN\$"
else
    # For prefix (default and recommended)
    $PROFANITY_BIN --matching "^$PATTERN"
fi

echo ""
echo "=== Search complete! ==="
echo "Private key and address shown above"
echo ""
echo "⚠️  SAVE THE PRIVATE KEY IMMEDIATELY!"
echo "⚠️  Import it into MetaMask, Phantom, or other wallet"
