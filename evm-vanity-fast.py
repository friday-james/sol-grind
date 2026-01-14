#!/usr/bin/env python3
"""
Fast EVM vanity address generator with multiprocessing
"""

import sys
import time
import secrets
import multiprocessing as mp
from eth_keys import keys
from eth_utils import to_checksum_address

def worker(pattern, position, case_sensitive, queue, stop_event):
    """Worker process to generate addresses"""
    pattern_lower = pattern.lower()
    local_count = 0

    while not stop_event.is_set():
        # Generate random private key
        private_key_bytes = secrets.token_bytes(32)
        private_key = keys.PrivateKey(private_key_bytes)

        # Derive address
        address = private_key.public_key.to_checksum_address()
        address_lower = address.lower()

        local_count += 1

        # Send count update every 1000 keys
        if local_count % 1000 == 0:
            queue.put(('count', local_count))
            local_count = 0

        # Check match
        if position == 'prefix':
            match = address_lower[2:].startswith(pattern_lower) if not case_sensitive else address[2:].startswith(pattern)
        else:
            match = address_lower.endswith(pattern_lower) if not case_sensitive else address.endswith(pattern)

        if match:
            queue.put(('found', address, private_key_bytes.hex()))
            stop_event.set()
            return

def generate_vanity_parallel(pattern, position='prefix', case_sensitive=False, num_workers=None):
    """Generate vanity address using multiple processes"""
    if num_workers is None:
        num_workers = mp.cpu_count()

    print(f"Searching for pattern: 0x{pattern} ({position})")
    print(f"Case-sensitive: {case_sensitive}")
    print(f"Using {num_workers} CPU cores")
    print("Press Ctrl+C to stop\n")

    # Create queue and stop event
    queue = mp.Queue()
    stop_event = mp.Event()

    # Start worker processes
    workers = []
    for _ in range(num_workers):
        p = mp.Process(target=worker, args=(pattern, position, case_sensitive, queue, stop_event))
        p.start()
        workers.append(p)

    # Monitor progress
    total_count = 0
    start_time = time.time()
    last_print = start_time
    found = False

    try:
        while not found:
            # Check queue for messages
            try:
                msg = queue.get(timeout=0.1)

                if msg[0] == 'count':
                    total_count += msg[1]
                elif msg[0] == 'found':
                    found = True
                    address = msg[1]
                    private_key_hex = msg[2]

                    elapsed = time.time() - start_time
                    print(f"\n{'='*60}")
                    print(f"FOUND in {elapsed:.1f} seconds after {total_count:,} attempts!")
                    print(f"{'='*60}")
                    print(f"\nAddress:     {address}")
                    print(f"Private Key: 0x{private_key_hex}")
                    print(f"\n{'='*60}")
                    print("⚠️  SAVE THE PRIVATE KEY IMMEDIATELY!")
                    print("⚠️  Import into MetaMask or other wallet")
                    print(f"{'='*60}\n")
                    break

            except:
                pass

            # Print speed every 2 seconds
            current_time = time.time()
            if current_time - last_print >= 2:
                elapsed = current_time - start_time
                rate = total_count / elapsed if elapsed > 0 else 0
                print(f"Speed: {rate:,.0f} keys/s | Checked: {total_count:,} keys")
                last_print = current_time

    except KeyboardInterrupt:
        print("\n\nSearch stopped by user")
        stop_event.set()

    # Wait for workers to finish
    for p in workers:
        p.terminate()
        p.join()

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 evm-vanity-fast.py <pattern> [prefix|suffix] [case-sensitive]")
        print("\nExamples:")
        print("  python3 evm-vanity-fast.py 1ead")
        print("  python3 evm-vanity-fast.py cafe prefix")
        print("  python3 evm-vanity-fast.py dead suffix true")
        sys.exit(1)

    pattern = sys.argv[1]
    position = sys.argv[2] if len(sys.argv) > 2 else 'prefix'
    case_sensitive = sys.argv[3].lower() == 'true' if len(sys.argv) > 3 else False

    # Validate hex
    try:
        int(pattern, 16)
    except ValueError:
        print(f"Error: '{pattern}' is not valid hex (use only 0-9, a-f)")
        sys.exit(1)

    generate_vanity_parallel(pattern, position, case_sensitive)
