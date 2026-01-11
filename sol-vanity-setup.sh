#!/bin/bash
set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <suffix>"
    exit 1
fi

SUFFIX="$1"

echo "=== Solana Vanity Address Generator Setup ==="
echo "Target suffix: $SUFFIX (case-insensitive)"
echo ""

# Update system
echo "[1/5] Updating system..."
sudo apt-get update -qq

# Install dependencies
echo "[2/5] Installing dependencies..."
sudo apt-get install -y -qq build-essential pkg-config libssl-dev git curl

# Install Rust if not present
if ! command -v cargo &> /dev/null; then
    echo "[3/5] Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
else
    echo "[3/5] Rust already installed"
    source "$HOME/.cargo/env" 2>/dev/null || true
fi

# Check for NVIDIA GPU
echo "[4/5] Checking GPU..."
if command -v nvidia-smi &> /dev/null; then
    nvidia-smi --query-gpu=name,memory.total --format=csv,noheader
    echo ""
else
    echo "WARNING: nvidia-smi not found. Make sure NVIDIA drivers are installed."
fi

# Clone and build GPU vanity generator
echo "[5/5] Building vanity generator..."
cd /tmp

# Try GPU-accelerated Zig tool (fastest)
echo "Trying grincel.gpu (Zig/Vulkan GPU accelerated)..."
if git clone https://github.com/ziglana/grincel.gpu.git 2>/dev/null; then
    cd grincel.gpu

    # Install Zig
    if ! command -v zig &> /dev/null; then
        echo "Installing Zig..."
        wget -q https://ziglang.org/download/0.11.0/zig-linux-x86_64-0.11.0.tar.xz
        tar -xf zig-linux-x86_64-0.11.0.tar.xz
        export PATH="$PWD/zig-linux-x86_64-0.11.0:$PATH"
    fi

    # Install Vulkan SDK
    sudo apt-get install -y -qq vulkan-tools libvulkan-dev vulkan-validationlayers

    echo "Building grincel.gpu..."
    zig build -Doptimize=ReleaseFast

    echo ""
    echo "=== Starting GPU Search (Zig/Vulkan) ==="
    echo "Looking for address ending with: $SUFFIX"
    echo ""

    ./zig-out/bin/grincel.gpu --suffix "$SUFFIX"
    exit 0
fi

# Fallback: Try OpenCL-based SolVanityCL
echo "Trying SolVanityCL (OpenCL GPU accelerated)..."
if git clone https://github.com/WincerChan/SolVanityCL.git 2>/dev/null; then
    cd SolVanityCL

    sudo apt-get install -y -qq ocl-icd-opencl-dev opencl-headers clinfo
    cargo build --release

    echo ""
    echo "=== Starting GPU Search (OpenCL) ==="
    echo "Looking for address ending with: $SUFFIX"
    echo ""

    ./target/release/sol_vanity_cl --suffix "$SUFFIX"
    exit 0
fi

# Final fallback: CPU
echo ""
echo "GPU tools unavailable, using CPU fallback..."
echo "=== Starting CPU-based search (slower) ==="
echo "Looking for address ending with: $SUFFIX"
echo ""
export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"
solana-keygen grind --ends-with "$SUFFIX":1 --num-threads $(nproc)

