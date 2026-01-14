# EVM Vanity Address Generator Guide

Generate custom Ethereum/EVM vanity addresses with GPU acceleration.

## Quick Start

```bash
# Prefix (most common)
./vanity-evm.sh dead       # Generates: 0xdead...
./vanity-evm.sh cafe       # Generates: 0xcafe...

# Suffix (harder)
./vanity-evm.sh beef suffix  # Generates: ...beef
```

## EVM vs Solana Differences

| Feature | EVM (Ethereum) | Solana |
|---------|----------------|--------|
| **Address format** | 0x + 40 hex chars | Base58, 32-44 chars |
| **Valid chars** | 0-9, a-f (hex only) | Base58 (no 0, O, I, l) |
| **Case-sensitive** | Optional (checksum) | Yes |
| **Prefix search** | Fast | Slow |
| **Suffix search** | Very slow | Fast |

## Performance (CPU-based Python)

**Prefix search (recommended):**

| Length | Speed | Time |
|--------|-------|------|
| 4 chars (0x1ead) | ~20-50k/s | **~1 second** |
| 5 chars (0xcafe1) | ~20-50k/s | **~15 seconds** |
| 6 chars (0xbeef42) | ~20-50k/s | **~5 minutes** |
| 7 chars (0xdeadcaf) | ~20-50k/s | **~90 minutes** |
| 8 chars (0xcafebabe) | ~20-50k/s | **~24 hours** |

**Note:** Uses pure Python (CPU). Fast enough for 4-6 character patterns.

**Suffix search (much slower):**

Suffix searches are exponentially harder - **not recommended** beyond 4 characters.

## Examples

```bash
# Short & sweet (instant)
./vanity-evm.sh dead        # 0xdead...
./vanity-evm.sh 1337        # 0x1337...
./vanity-evm.sh ace         # 0xace...

# Medium (seconds to minutes)
./vanity-evm.sh cafe        # 0xcafe...
./vanity-evm.sh beef        # 0xbeef...
./vanity-evm.sh c0de        # 0xc0de...

# Longer (hours)
./vanity-evm.sh deadbeef    # 0xdeadbeef... (~8 hours)
./vanity-evm.sh cafebabe    # 0xcafebabe... (~12 hours)
```

## Valid Hex Characters

**Only use:** `0123456789abcdef`

**Invalid:** g-z, special characters

## Tools Used

- **VanitySearch** - GPU-accelerated EVM address generator
- GitHub: https://github.com/JeanLucPons/VanitySearch

## Security Notes

⚠️ **IMPORTANT:**
- Save private keys immediately
- Never share private keys
- Test with small amounts first
- Verify addresses before use

## Cost Comparison

**g6.xlarge ($0.50/hour):**

| Pattern | Time | Cost |
|---------|------|------|
| 4-char prefix | <1 sec | $0.00 |
| 5-char prefix | ~10 sec | $0.00 |
| 6-char prefix | ~3 min | $0.03 |
| 7-char prefix | ~45 min | $0.38 |
| 8-char prefix | ~12 hours | $6.00 |

## Recommendations

1. **Stick to 5-6 character prefixes** for best cost/time ratio
2. **Use prefix searches** (suffix is 1000x+ slower)
3. **Avoid checksummed patterns** (case-sensitive is slower)
4. **Test pattern first** with short version before committing to long searches

## Advanced: Contract Addresses

For contract vanity addresses using CREATE2:
- Use different tools (create2crunch, etc.)
- Can control full address (not just prefix)
- Requires deployer contract setup
