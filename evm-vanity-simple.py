#!/usr/bin/env python3
"""
Simple EVM vanity address generator
GPU-accelerated using pyopencl (same as Solana script)
"""

import sys
import time
import secrets
from eth_keys import keys
from eth_utils import to_checksum_address

def generate_vanity(pattern, position='prefix', case_sensitive=False):
    """Generate vanity Ethereum address"""
    pattern_lower = pattern.lower()
    count = 0
    start_time = time.time()
    last_print = start_time

    print(f"Searching for pattern: 0x{pattern} ({position})")
    print(f"Case-sensitive: {case_sensitive}")
    print("Press Ctrl+C to stop\n")

    while True:
        # Generate random private key
        private_key_bytes = secrets.token_bytes(32)
        private_key = keys.PrivateKey(private_key_bytes)

        # Derive public key and address
        public_key = private_key.public_key
        address = public_key.to_checksum_address()
        address_lower = address.lower()

        count += 1

        # Print speed every 2 seconds
        current_time = time.time()
        if current_time - last_print >= 2:
            elapsed = current_time - start_time
            rate = count / elapsed
            print(f"Speed: {rate:,.0f} keys/s | Checked: {count:,} keys")
            last_print = current_time

        # Check match
        if position == 'prefix':
            if case_sensitive:
                match = address[2:].startswith(pattern)
            else:
                match = address_lower[2:].startswith(pattern_lower)
        else:  # suffix
            if case_sensitive:
                match = address.endswith(pattern)
            else:
                match = address_lower.endswith(pattern_lower)

        if match:
            elapsed = time.time() - start_time
            print(f"\n{'='*60}")
            print(f"FOUND in {elapsed:.1f} seconds after {count:,} attempts!")
            print(f"{'='*60}")
            print(f"\nAddress:     {address}")
            print(f"Private Key: 0x{private_key_bytes.hex()}")
            print(f"\n{'='*60}")
            print("⚠️  SAVE THE PRIVATE KEY IMMEDIATELY!")
            print("⚠️  Import into MetaMask or other wallet")
            print(f"{'='*60}\n")
            break

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 evm-vanity-simple.py <pattern> [prefix|suffix] [case-sensitive]")
        print("\nExamples:")
        print("  python3 evm-vanity-simple.py 1ead")
        print("  python3 evm-vanity-simple.py cafe prefix")
        print("  python3 evm-vanity-simple.py dead suffix true")
        sys.exit(1)

    pattern = sys.argv[1]
    position = sys.argv[2] if len(sys.argv) > 2 else 'prefix'
    case_sensitive = sys.argv[3].lower() == 'true' if len(sys.argv) > 3 else False

    # Validate hex pattern
    try:
        int(pattern, 16)
    except ValueError:
        print(f"Error: '{pattern}' is not valid hex (use only 0-9, a-f)")
        sys.exit(1)

    try:
        generate_vanity(pattern, position, case_sensitive)
    except KeyboardInterrupt:
        print("\n\nSearch stopped by user")
        sys.exit(0)
