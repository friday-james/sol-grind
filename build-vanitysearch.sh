#!/bin/bash
set -e

echo "=== Building VanitySearch with GPU support ==="

# Install dependencies
sudo apt-get update -qq
sudo apt-get install -y -qq git build-essential libgmp3-dev nvidia-cuda-toolkit gcc-12 g++-12

# Clone VanitySearch
cd /tmp
rm -rf VanitySearch
git clone https://github.com/JeanLucPons/VanitySearch.git
cd VanitySearch

echo "[*] Patching source files for modern compiler..."

# Fix Timer.h - add missing include
sed -i '/#include <string>/a #include <cstdint>' Timer.h

# Fix hash/sha256.cpp - add missing include
sed -i '1i #include <cstdint>' hash/sha256.cpp

# Fix hash/ripemd160.cpp - add missing include
sed -i '1i #include <cstdint>' hash/ripemd160.cpp

# Fix Makefile - use current CUDA path and gcc-12
CUDA_PATH=$(dirname $(dirname $(which nvcc)))
sed -i "s|/usr/local/cuda-8.0|$CUDA_PATH|g" Makefile
sed -i "s|/usr/local/cuda|$CUDA_PATH|g" Makefile
sed -i 's|g++-4.8|g++-12|g' Makefile
sed -i 's|gcc-4.8|gcc-12|g' Makefile
sed -i 's|-ccbin /usr/bin/g++|-ccbin /usr/bin/g++-12|g' Makefile

echo "[*] Building with GPU support (compute capability 7.5 for L4)..."
make clean 2>&1 | tee build.log
make gpu=1 CCAP=75 2>&1 | tee -a build.log

if [ -f "VanitySearch" ]; then
    echo ""
    # Verify GPU support was compiled in
    if ./VanitySearch -gpu -check 2>&1 | grep -q "GPU code not compiled"; then
        echo "❌ GPU support not compiled!"
        echo ""
        echo "Build log:"
        cat build.log
        exit 1
    fi

    echo "✅ Build successful with GPU support!"
    echo "Binary: /tmp/VanitySearch/VanitySearch"
    echo ""
    ./VanitySearch -gpu -check
else
    echo "❌ Build failed"
    echo ""
    echo "Build log:"
    cat build.log
    exit 1
fi
