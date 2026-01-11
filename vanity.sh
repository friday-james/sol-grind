#!/bin/bash
set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <suffix> [case-sensitive: true|false]"
    echo "Example: $0 ifsa1e false"
    exit 1
fi

SUFFIX="$1"
CASE_SENSITIVE="${2:-false}"

echo "=== Solana GPU Vanity Generator ==="
echo "Suffix: $SUFFIX"
echo "Case-sensitive: $CASE_SENSITIVE"
echo ""

# Check GPU
if ! nvidia-smi &> /dev/null; then
    echo "ERROR: NVIDIA GPU not detected or drivers not loaded."
    echo "Run: sudo reboot"
    exit 1
fi

echo "[*] GPU detected:"
nvidia-smi --query-gpu=name --format=csv,noheader
echo ""

# Install dependencies
echo "[*] Installing dependencies..."
sudo apt-get update -qq
sudo apt-get install -y -qq git python3-pip python3-dev ocl-icd-opencl-dev opencl-headers

# Install Python packages
echo "[*] Installing Python packages..."
pip3 install --break-system-packages pyopencl base58 click PyNaCl 2>&1 | grep -E "Successfully installed|already satisfied" || true

# Clone SolVanityCL
cd /tmp
if [ -d "SolVanityCL" ]; then
    echo "[*] Using existing SolVanityCL..."
    cd SolVanityCL
else
    echo "[*] Cloning SolVanityCL..."
    git clone https://github.com/WincerChan/SolVanityCL.git
    cd SolVanityCL
fi

# Run search
echo ""
echo "=== Starting GPU Search ==="
echo "Searching for: *$SUFFIX (case-sensitive: $CASE_SENSITIVE)"
echo "Press Ctrl+C to stop"
echo ""

if [ "$CASE_SENSITIVE" = "true" ] || [ "$CASE_SENSITIVE" = "True" ]; then
    python3 main.py search-pubkey --ends-with "$SUFFIX" --is-case-sensitive True
else
    python3 main.py search-pubkey --ends-with "$SUFFIX" --is-case-sensitive False
fi

echo ""
echo "=== Search complete! ==="
echo "Check current directory for keypair JSON file."
