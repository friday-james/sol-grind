#!/bin/bash
set -e

echo "=== Building VanitySearch with GPU support ==="

# Install dependencies
sudo apt-get update -qq
sudo apt-get install -y -qq git build-essential libgmp3-dev nvidia-cuda-toolkit

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

# Fix Makefile - use current CUDA path and add unsupported compiler flag
CUDA_PATH=$(dirname $(dirname $(which nvcc)))
sed -i "s|/usr/local/cuda-8.0|$CUDA_PATH|g" Makefile
sed -i "s|/usr/local/cuda|$CUDA_PATH|g" Makefile
sed -i 's|g++-4.8|g++|g' Makefile
sed -i 's|gcc-4.8|gcc|g' Makefile

# Add -allow-unsupported-compiler flag for newer gcc
sed -i 's|NVCC = $(CUDA)/bin/nvcc|NVCC = $(CUDA)/bin/nvcc -allow-unsupported-compiler|g' Makefile

echo "[*] Building with GPU support (compute capability 7.5 for L4)..."
make gpu=1 CCAP=75

if [ -f "VanitySearch" ]; then
    echo ""
    echo "✅ Build successful!"
    echo "Binary: /tmp/VanitySearch/VanitySearch"
    echo ""
    echo "Test it:"
    echo "  cd /tmp/VanitySearch"
    echo "  ./VanitySearch -gpu -check"
    echo "  ./VanitySearch -gpu 1ead"
else
    echo "❌ Build failed"
    exit 1
fi
