#!/bin/bash
set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <suffix>"
    exit 1
fi

SUFFIX="$1"

echo "=== Solana GPU Vanity Generator ==="
echo "Target: address ending with '$SUFFIX' (case-insensitive)"
echo ""

# Check GPU and install drivers if needed
echo "[*] Checking GPU..."
if ! nvidia-smi &> /dev/null; then
    if ! command -v nvidia-smi &> /dev/null; then
        echo "NVIDIA drivers not found. Installing now..."
    else
        echo "NVIDIA drivers installed but not loaded. Installing/updating..."
    fi
    echo ""

    # Update package list
    sudo apt-get update -qq

    # For AWS instances, use ubuntu-drivers for best compatibility
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
    echo "  cd ~/sol-grind && ./sol-vanity-gpu.sh $SUFFIX"
    echo ""
    echo "Rebooting in 5 seconds... (Ctrl+C to cancel)"
    sleep 5
    sudo reboot
fi

echo "[*] GPU Info:"
nvidia-smi --query-gpu=name,memory.total,driver_version --format=csv,noheader
echo ""

# Install dependencies
echo "[*] Installing dependencies..."
sudo apt-get update -qq
sudo apt-get install -y -qq build-essential git curl wget pkg-config libssl-dev

# Install CUDA toolkit if nvcc not found
if ! command -v nvcc &> /dev/null; then
    echo "[*] Installing CUDA toolkit..."
    sudo apt-get install -y -qq nvidia-cuda-toolkit
fi

# Install Rust
if ! command -v cargo &> /dev/null; then
    echo "[*] Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
fi
source "$HOME/.cargo/env" 2>/dev/null || true

# Install Solana CLI
if ! command -v solana-keygen &> /dev/null; then
    echo "[*] Installing Solana CLI (Agave v2.0.14)..."
    # Solana v2.0+ is now maintained as Agave by Anza
    wget -q https://github.com/anza-xyz/agave/releases/download/v2.0.14/solana-release-x86_64-unknown-linux-gnu.tar.bz2 -O /tmp/solana-release.tar.bz2
    tar -xjf /tmp/solana-release.tar.bz2 -C /tmp
    mkdir -p "$HOME/.local/share/solana/install/active_release"
    cp -r /tmp/solana-release/bin "$HOME/.local/share/solana/install/active_release/"
    rm -rf /tmp/solana-release /tmp/solana-release.tar.bz2
fi
export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"

# Clone GPU vanity tool
echo "[*] Setting up GPU vanity generator..."
cd /tmp

# Try GPU-accelerated Zig tool first (fastest)
if [ ! -d "grincel.gpu" ]; then
    echo "[*] Cloning grincel.gpu (Zig/Vulkan GPU accelerated)..."
    if git clone https://github.com/ziglana/grincel.gpu.git 2>/dev/null; then
        cd grincel.gpu

        # Install Zig if not present
        if ! command -v zig &> /dev/null; then
            echo "[*] Installing Zig 0.13.0..."
            wget -q https://ziglang.org/download/0.13.0/zig-linux-x86_64-0.13.0.tar.xz
            tar -xf zig-linux-x86_64-0.13.0.tar.xz
            export PATH="$PWD/zig-linux-x86_64-0.13.0:$PATH"
        fi

        # Install Vulkan SDK for GPU compute
        if ! dpkg -l | grep -q vulkan-tools; then
            echo "[*] Installing Vulkan SDK..."
            sudo apt-get install -y -qq vulkan-tools libvulkan-dev vulkan-validationlayers
        fi

        echo "[*] Building grincel.gpu..."
        if zig build -Doptimize=ReleaseFast 2>&1; then
            if [ -f "./zig-out/bin/grincel.gpu" ]; then
                echo ""
                echo "=== Starting GPU Search (Zig/Vulkan) ==="
                echo "Searching for: *$SUFFIX"
                echo "Press Ctrl+C when found"
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
fi

# Fallback to OpenCL-based SolVanityCL (Python/C)
echo "[*] Trying SolVanityCL (OpenCL GPU accelerated)..."
if [ ! -d "SolVanityCL" ]; then
    if git clone https://github.com/WincerChan/SolVanityCL.git 2>/dev/null; then
        cd SolVanityCL

        # Install OpenCL and Python dependencies
        echo "[*] Installing OpenCL and Python dependencies..."
        sudo apt-get install -y -qq ocl-icd-opencl-dev opencl-headers clinfo python3-pip python3-dev

        # Install Python packages directly (use --break-system-packages for Ubuntu 24.04+)
        echo "[*] Installing Python packages (pyopencl, base58, etc)..."
        pip3 install --break-system-packages pyopencl base58 click 2>&1 | grep -v "already satisfied" || true

        echo ""
        echo "=== Starting GPU Search (OpenCL/Python) ==="
        echo "Searching for: *$SUFFIX"
        echo "Press Ctrl+C when found"
        echo ""

        python3 main.py search-pubkey --ends-with "$SUFFIX" --is-case-sensitive False
        exit 0
    fi
fi

# Final fallback to CPU
echo ""
echo "[!] GPU tools failed, using CPU fallback..."
echo "[*] Starting search with $(nproc) threads..."
echo ""
export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"
solana-keygen grind --ends-with "$SUFFIX":1 --num-threads $(nproc)
