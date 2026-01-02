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

# Check GPU
echo "[*] GPU Info:"
nvidia-smi --query-gpu=name,memory.total,driver_version --format=csv,noheader || {
    echo "ERROR: No NVIDIA GPU detected. Install drivers first."
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
cd ~
if [ ! -d "solana-vanity-gpu" ]; then
    # Try multiple known GPU vanity repos
    git clone https://github.com/paxsonsa/vaniSOL.git solana-vanity-gpu 2>/dev/null || \
    git clone https://github.com/Azoyalabs/solana-vanity-keygen.git solana-vanity-gpu 2>/dev/null || {
        echo ""
        echo "[!] GPU tools unavailable, using CPU fallback (slower but works)..."
        echo "[*] Starting search with $(nproc) threads..."
        echo ""
        solana-keygen grind --ends-with "$SUFFIX":1 --ignore-case --num-threads $(nproc)
        exit 0
    }
fi

cd solana-vanity-gpu
cargo build --release

echo ""
echo "=== Starting GPU Search ==="
echo "Searching for: *$SUFFIX (case-insensitive)"
echo "Press Ctrl+C to stop"
echo ""

# Run with appropriate args based on which tool was cloned
if [ -f "target/release/vanisol" ]; then
    ./target/release/vanisol --suffix "$SUFFIX" --ignore-case
elif [ -f "target/release/solana-vanity-keygen" ]; then
    ./target/release/solana-vanity-keygen --suffix "$SUFFIX"
else
    echo "Running default binary..."
    ./target/release/* --suffix "$SUFFIX" --ignore-case 2>/dev/null || \
    cargo run --release -- --suffix "$SUFFIX" --ignore-case
fi
