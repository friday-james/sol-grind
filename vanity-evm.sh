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
        # Detect CUDA path
        if [ -d "/usr/local/cuda" ]; then
            export CUDA_PATH=/usr/local/cuda
        elif [ -d "/usr/lib/cuda" ]; then
            export CUDA_PATH=/usr/lib/cuda
        fi

        # Update Makefile to use installed CUDA and gcc
        sed -i 's|/usr/local/cuda-8.0|/usr/local/cuda|g' Makefile
        sed -i 's|g++-4.8|g++|g' Makefile
        sed -i 's|gcc-4.8|gcc|g' Makefile

        # Build with GPU support (compute capability 7.5 for L4)
        make gpu=1 CCAP=75 2>&1 | tee build.log

        if [ ! -f "VanitySearch" ]; then
            echo "GPU build failed, trying CPU mode..."
            make clean
            make
        fi
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
