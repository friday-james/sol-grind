# Solana Vanity Address Generator

GPU-accelerated Solana vanity address generator scripts for AWS GPU instances (g6.xlarge, g4dn, g5, etc).

## Features

- **Automatic NVIDIA driver installation** with reboot handling
- **GPU acceleration** using Zig/Vulkan (grincel.gpu) or OpenCL (SolVanityCL)
- **CPU fallback** using solana-keygen if GPU tools fail
- **AWS optimized** with ubuntu-drivers compatibility

## Quick Start

### One-Shot Script (Recommended)

```bash
# Clone the repo
git clone https://github.com/friday-james/sol-grind.git
cd sol-grind

# Run the one-shot script
./vanity.sh ifsa1e

# Or with case-sensitive mode
./vanity.sh ifsa1e true
```

**That's it!** The script handles everything automatically.

### Full Setup Script (First Time on Fresh Instance)

```bash
# Run the GPU script with your desired suffix
./sol-vanity-gpu.sh ifsa1e
```

The script will:
1. Detect and install NVIDIA drivers if needed
2. Auto-reboot if required (drivers must be loaded)
3. After reboot, run the same command again
4. Install GPU vanity generator tools
5. Start searching for your vanity address

## Performance

| Hardware | Keys/Second | Time (case-insensitive) | Time (case-sensitive) |
|----------|-------------|-------------------------|------------------------|
| CPU (16 threads) | ~167k | ~2 hours | ~63 hours |
| NVIDIA L4 (g6.xlarge) | 20-25M | **1-2 min** | ~30 min |
| NVIDIA A10G (g5.xlarge) | 100-200M | **<1 min** | 3-7 min |

**Note:** Case-insensitive is **30x faster** (matches any case: `ifsa1e`, `IFSA1E`, `IfSa1E`, etc.)

## Scripts

### `vanity.sh` ⭐ (Recommended)

One-shot script that just works. No fuss, no configuration.

```bash
./vanity.sh <suffix> [case-sensitive]
```

**Arguments:**
- `suffix` - The ending you want (e.g., `ifsa1e`)
- `case-sensitive` - Optional: `true` or `false` (default: `false`)

**Example:**
```bash
./vanity.sh ifsa1e        # Case-insensitive (fast, ~1-2 min)
./vanity.sh ifsa1e false  # Same as above
./vanity.sh ifsa1e true   # Case-sensitive (slow, ~30 min)
```

### `sol-vanity-gpu.sh`

Full setup script with driver installation and fallback options.

```bash
./sol-vanity-gpu.sh <suffix>
```

**Features:**
- Automatic NVIDIA driver detection and installation
- Auto-reboot prompt when drivers need loading
- Tries multiple GPU tools in order:
  1. grincel.gpu (Zig/Vulkan - fastest)
  2. SolVanityCL (OpenCL/Rust - reliable)
  3. CPU fallback (solana-keygen)

### `sol-vanity-setup.sh`

Setup script with full installation flow.

```bash
./sol-vanity-setup.sh <suffix>
```

Same features as `sol-vanity-gpu.sh` but optimized for first-time setup.

## Valid Characters

Solana addresses use **base58 encoding**. Only these characters are valid:

```
123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz
```

**Excluded characters** (to avoid confusion):
- `0` (zero) - conflicts with `O`
- `O` (uppercase o) - conflicts with `0`
- `I` (uppercase i) - conflicts with `1` and `l`
- `l` (lowercase L) - conflicts with `1` and `I`

## Examples

```bash
# Valid suffixes
./sol-vanity-gpu.sh ifsa1e
./sol-vanity-gpu.sh monkey
./sol-vanity-gpu.sh 420blazeit

# Invalid (contains 'l' or 'O')
./sol-vanity-gpu.sh illegal   # ❌ contains 'l'
./sol-vanity-gpu.sh MOON      # ❌ contains 'O'
```

## Security Notes

⚠️ **IMPORTANT**:
- Save the **private key** immediately when found
- The scripts do NOT save keys automatically
- Store private keys securely (never share them)
- Use generated addresses at your own risk

## Requirements

- Ubuntu 20.04/22.04/24.04
- NVIDIA GPU (for GPU acceleration)
- sudo access (for driver installation)

## Troubleshooting

### nvidia-smi fails after installation

```bash
# Reboot to load drivers
sudo reboot
```

### Script can't find nvidia-smi after reboot

```bash
# Re-run the script, it will detect and fix
./sol-vanity-gpu.sh ifsa1e
```

### GPU tools fail to build

The script will automatically fall back to CPU mode using `solana-keygen`.

## GPU Tools Used

- [grincel.gpu](https://github.com/ziglana/grincel.gpu) - Zig/Vulkan GPU accelerated
- [SolVanityCL](https://github.com/WincerChan/SolVanityCL) - OpenCL/Rust GPU accelerated

## License

MIT
