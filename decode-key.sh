#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: $0 <path-to-keypair.json>"
    echo "Example: $0 /tmp/SolVanityCL/*.json"
    exit 1
fi

KEYPAIR_FILE="$1"

if [ ! -f "$KEYPAIR_FILE" ]; then
    echo "Error: File not found: $KEYPAIR_FILE"
    exit 1
fi

echo "=== Solana Keypair Decoder ==="
echo "Reading: $KEYPAIR_FILE"
echo ""

python3 << EOF
import json
import base58

# Read the keypair file
with open('$KEYPAIR_FILE', 'r') as f:
    key_bytes = bytes(json.load(f))

# Convert to base58
private_key_base58 = base58.b58encode(key_bytes).decode('utf-8')
public_key_base58 = base58.b58encode(key_bytes[32:]).decode('utf-8')

print("=" * 60)
print("PUBLIC KEY (Address):")
print(public_key_base58)
print("")
print("PRIVATE KEY (Secret - NEVER SHARE):")
print(private_key_base58)
print("=" * 60)
print("")
print("⚠️  SAVE THE PRIVATE KEY SECURELY!")
print("⚠️  Use it to import into Phantom, Solflare, etc.")
print("⚠️  Anyone with this key controls the wallet!")
print("")
EOF
