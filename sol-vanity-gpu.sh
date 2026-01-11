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
if ! command -v nvidia-smi &> /dev/null; then
    echo "NVIDIA drivers not found. Installing now..."
    echo ""

    # Update package list
    sudo apt-get update -qq

    # Install NVIDIA drivers
    echo "Installing NVIDIA drivers (this may take a few minutes)..."
    sudo apt-get install -y nvidia-driver-535 || {
        echo "ERROR: Failed to install NVIDIA drivers"
        exit 1
    }

    echo ""
    echo "=========================================="
    echo "NVIDIA drivers installed successfully!"
    echo "=========================================="
    echo ""
    echo "A REBOOT is REQUIRED for drivers to load."
    echo ""
    echo "After reboot, run this script again:"
    echo "  ./sol-vanity-gpu.sh $SUFFIX"
    echo ""
    read -p "Reboot now? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo reboot
    else
        echo "Please reboot manually with: sudo reboot"
        exit 0
    fi
fi

echo "[*] GPU Info:"
nvidia-smi --query-gpu=name,memory.total,driver_version --format=csv,noheader || {
    echo "ERROR: nvidia-smi found but GPU not detected."
    echo "You may need to reboot: sudo reboot"
    exit 1
}
echo ""

# Install dependencies
echo "[*] Installing dependencies..."
sudo apt-get update -qq
sudo apt-get install -y -qq build-essential git curl pkg-config libssl-dev

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
    echo "[*] Installing Solana CLI..."
    sh -c "$(curl -sSfL https://release.solana.com/stable/install)"
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
            echo "[*] Installing Zig..."
            wget -q https://ziglang.org/download/0.11.0/zig-linux-x86_64-0.11.0.tar.xz
            tar -xf zig-linux-x86_64-0.11.0.tar.xz
            export PATH="$PWD/zig-linux-x86_64-0.11.0:$PATH"
        fi

        # Install Vulkan SDK for GPU compute
        if ! dpkg -l | grep -q vulkan-tools; then
            echo "[*] Installing Vulkan SDK..."
            sudo apt-get install -y -qq vulkan-tools libvulkan-dev vulkan-validationlayers
        fi

        echo "[*] Building grincel.gpu..."
        zig build -Doptimize=ReleaseFast

        echo ""
        echo "=== Starting GPU Search (Zig/Vulkan) ==="
        echo "Searching for: *$SUFFIX"
        echo "Press Ctrl+C when found"
        echo ""

        ./zig-out/bin/grincel.gpu --suffix "$SUFFIX"
        exit 0
    fi
fi

# Fallback to OpenCL-based SolVanityCL
echo "[*] Trying SolVanityCL (OpenCL GPU accelerated)..."
if [ ! -d "SolVanityCL" ]; then
    if git clone https://github.com/WincerChan/SolVanityCL.git 2>/dev/null; then
        cd SolVanityCL

        # Install OpenCL dependencies
        echo "[*] Installing OpenCL dependencies..."
        sudo apt-get install -y -qq ocl-icd-opencl-dev opencl-headers clinfo

        # Install Rust dependencies
        cargo build --release

        echo ""
        echo "=== Starting GPU Search (OpenCL) ==="
        echo "Searching for: *$SUFFIX"
        echo "Press Ctrl+C when found"
        echo ""

        ./target/release/sol_vanity_cl --suffix "$SUFFIX"
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
