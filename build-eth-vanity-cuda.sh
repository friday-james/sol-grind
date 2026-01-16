#!/bin/bash
set -e

echo "=== Building eth-vanity-cuda (GPU Ethereum Vanity) ==="

# Install dependencies
sudo apt-get update -qq
sudo apt-get install -y -qq git build-essential nvidia-cuda-toolkit gcc-12 g++-12

# Clone eth-vanity-cuda
cd /tmp
rm -rf eth-vanity-cuda
git clone https://github.com/manuelinfosec/eth-vanity-cuda.git
cd eth-vanity-cuda

echo "[*] Building with CUDA support (L4 GPU)..."

# Compile with gcc-12 for CUDA compatibility (main.cu is in src/)
nvcc -O3 -arch=sm_75 --compiler-bindir=/usr/bin/g++-12 -o eth-vanity src/main.cu

if [ -f "eth-vanity" ]; then
    echo ""
    echo "✅ Build successful!"
    echo "Binary: /tmp/eth-vanity-cuda/eth-vanity"
    echo ""
    echo "Test it:"
    echo "  cd /tmp/eth-vanity-cuda"
    echo "  ./eth-vanity --help"
else
    echo "❌ Build failed"
    exit 1
fi
