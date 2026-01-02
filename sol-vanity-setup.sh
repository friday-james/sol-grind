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

# Clone and build solana-vanity (GPU-accelerated)
echo "[5/5] Building vanity generator..."
cd /tmp

# Option 1: Use vaniSOL (popular GPU-accelerated option)
if [ ! -d "vaniSOL" ]; then
    git clone https://github.com/paxsonsa/vaniSOL.git 2>/dev/null || {
        echo "vaniSOL not available, trying alternative..."
        # Option 2: Use solana CLI with CPU (fallback)
        if ! command -v solana-keygen &> /dev/null; then
            echo "Installing Solana CLI tools..."
            sh -c "$(curl -sSfL https://release.solana.com/stable/install)"
            export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"
        fi
        echo ""
        echo "=== Starting CPU-based search (slower) ==="
        echo "Looking for address ending with: $SUFFIX"
        echo ""
        solana-keygen grind --ends-with "$SUFFIX":1 --ignore-case
        exit 0
    }
fi

cd vaniSOL
cargo build --release

echo ""
echo "=== Starting GPU-accelerated search ==="
echo "Looking for address ending with: $SUFFIX"
echo ""

./target/release/vanisol --suffix "$SUFFIX" --ignore-case

