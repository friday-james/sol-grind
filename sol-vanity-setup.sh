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
sudo apt-get install -y -qq build-essential pkg-config libssl-dev git curl wget

# Install Rust if not present
if ! command -v cargo &> /dev/null; then
    echo "[3/5] Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
else
    echo "[3/5] Rust already installed"
    source "$HOME/.cargo/env" 2>/dev/null || true
fi

# Check for NVIDIA GPU and install drivers if needed
echo "[4/5] Checking GPU..."
if ! nvidia-smi &> /dev/null; then
    if ! command -v nvidia-smi &> /dev/null; then
        echo "NVIDIA drivers not found. Installing now..."
    else
        echo "NVIDIA drivers installed but not loaded. Installing/updating..."
    fi
    echo ""

    # Install NVIDIA drivers
    echo "Installing NVIDIA drivers (this may take a few minutes)..."
    sudo apt-get install -y ubuntu-drivers-common
    sudo ubuntu-drivers install || sudo apt-get install -y nvidia-driver-535

    echo ""
    echo "=========================================="
    echo "NVIDIA drivers installed!"
    echo "=========================================="
    echo ""
    echo "*** REBOOT REQUIRED ***"
    echo ""
    echo "Run: sudo reboot"
    echo ""
    echo "After reboot, run this script again:"
    echo "  cd ~/sol-grind && ./sol-vanity-setup.sh $SUFFIX"
    echo ""
    echo "Rebooting in 5 seconds... (Ctrl+C to cancel)"
    sleep 5
    sudo reboot
else
    nvidia-smi --query-gpu=name,memory.total --format=csv,noheader
    echo ""
fi

# Install Solana CLI for CPU fallback
if ! command -v solana-keygen &> /dev/null; then
    echo "[4.5/5] Installing Solana CLI (Agave v2.0.14)..."
    # Solana v2.0+ is now maintained as Agave by Anza
    wget -q https://github.com/anza-xyz/agave/releases/download/v2.0.14/solana-release-x86_64-unknown-linux-gnu.tar.bz2 -O /tmp/solana-release.tar.bz2
    tar -xjf /tmp/solana-release.tar.bz2 -C /tmp
    mkdir -p "$HOME/.local/share/solana/install/active_release"
    cp -r /tmp/solana-release/bin "$HOME/.local/share/solana/install/active_release/"
    rm -rf /tmp/solana-release /tmp/solana-release.tar.bz2
fi
export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"

# Clone and build GPU vanity generator
echo "[5/5] Building vanity generator..."
cd /tmp

# Try GPU-accelerated Zig tool (fastest)
echo "Trying grincel.gpu (Zig/Vulkan GPU accelerated)..."
if git clone https://github.com/ziglana/grincel.gpu.git 2>/dev/null; then
    cd grincel.gpu

    # Install Zig
    if ! command -v zig &> /dev/null; then
        echo "Installing Zig 0.13.0..."
        wget -q https://ziglang.org/download/0.13.0/zig-linux-x86_64-0.13.0.tar.xz
        tar -xf zig-linux-x86_64-0.13.0.tar.xz
        export PATH="$PWD/zig-linux-x86_64-0.13.0:$PATH"
    fi

    # Install Vulkan SDK
    sudo apt-get install -y -qq vulkan-tools libvulkan-dev vulkan-validationlayers

    echo "Building grincel.gpu..."
    if zig build -Doptimize=ReleaseFast 2>&1; then
        if [ -f "./zig-out/bin/grincel.gpu" ]; then
            echo ""
            echo "=== Starting GPU Search (Zig/Vulkan) ==="
            echo "Looking for address ending with: $SUFFIX"
            echo ""

            ./zig-out/bin/grincel.gpu --suffix "$SUFFIX"
            exit 0
        else
            echo "Build succeeded but binary not found. Trying fallback..."
        fi
    else
        echo "Zig build failed. Trying fallback..."
    fi
fi

# Fallback: Try OpenCL-based SolVanityCL (Python/C)
echo "Trying SolVanityCL (OpenCL GPU accelerated)..."
if git clone https://github.com/WincerChan/SolVanityCL.git 2>/dev/null; then
    cd SolVanityCL

    sudo apt-get install -y -qq ocl-icd-opencl-dev opencl-headers clinfo python3-pip python3-dev

    # Install Python packages directly (use --break-system-packages for Ubuntu 24.04+)
    echo "Installing Python packages (pyopencl, base58, PyNaCl, etc)..."
    pip3 install --break-system-packages pyopencl base58 click PyNaCl 2>&1 | grep -v "already satisfied" || true

    echo ""
    echo "=== Starting GPU Search (OpenCL/Python) ==="
    echo "Looking for address ending with: $SUFFIX"
    echo ""

    python3 main.py search-pubkey --ends-with "$SUFFIX" --is-case-sensitive False
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

