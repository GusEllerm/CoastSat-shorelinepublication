# Interface.crate Version Configuration Reference

## Quick Reference: Setting Interface.crate Versions in publish_to_docs.sh

### 🎯 Command Syntax
```bash
./scripts/publish_to_docs.sh [SITE_ID] [INTERFACE_CRATE_VERSION] [COMPARISON_VERSION_1] [COMPARISON_VERSION_2]
```

### 📝 Arguments
- **SITE_ID**: The shoreline site to analyze (e.g., `nzd0021`, `aus0001`)
- **INTERFACE_CRATE_VERSION**: Version for the main publication (default: `latest`)
- **COMPARISON_VERSION_1**: First version for side-by-side comparison (default: `latest`)
- **COMPARISON_VERSION_2**: Second version for side-by-side comparison (default: `interface.crate-d61c2052a-20250725024714`)

### 🔧 Environment Variables
- **COMPARISON_V1**: Override first comparison version
- **COMPARISON_V2**: Override second comparison version

### 📋 Available Versions
| Version Tag | Release Date | Description |
|-------------|--------------|-------------|
| `latest` | Current | Most recent GitHub release |
| `interface.crate-cb67e8e26-20250801011405` | Aug 1, 2025 | August 2025 release |
| `interface.crate-d61c2052a-20250725024714` | Jul 25, 2025 | July 2025 release |

### 💡 Usage Examples

#### Example 1: Default Setup
```bash
./scripts/publish_to_docs.sh nzd0021
```
- Main publication: `latest`
- Comparison: `latest` vs `interface.crate-d61c2052a-20250725024714`

#### Example 2: All Arguments
```bash
./scripts/publish_to_docs.sh nzd0021 latest latest interface.crate-cb67e8e26-20250801011405
```
- Main publication: `latest`
- Comparison: `latest` vs `interface.crate-cb67e8e26-20250801011405`

#### Example 3: Environment Variables
```bash
COMPARISON_V1=interface.crate-cb67e8e26-20250801011405 COMPARISON_V2=interface.crate-d61c2052a-20250725024714 ./scripts/publish_to_docs.sh nzd0021
```
- Main publication: `latest`
- Comparison: `interface.crate-cb67e8e26-20250801011405` vs `interface.crate-d61c2052a-20250725024714`

#### Example 4: Australian Site with Specific Main Version
```bash
./scripts/publish_to_docs.sh aus0001 interface.crate-cb67e8e26-20250801011405 latest interface.crate-d61c2052a-20250725024714
```
- Main publication: `interface.crate-cb67e8e26-20250801011405`
- Comparison: `latest` vs `interface.crate-d61c2052a-20250725024714`

### 📂 Generated Files
The script creates these files in the `docs/` directory:
- `shorelinepublication.html` - Main publication (uses INTERFACE_CRATE_VERSION)
- `shorelinepublication-v1.html` - First comparison version (uses COMPARISON_VERSION_1)
- `shorelinepublication-v2.html` - Second comparison version (uses COMPARISON_VERSION_2)
- `version-comparison.html` - Side-by-side comparison interface

### 🔍 Finding Available Versions
To see all available interface.crate versions:
```bash
curl -s "https://api.github.com/repos/GusEllerm/CoastSat-interface.crate/releases" | grep '"tag_name"' | head -10
```

### ⚡ Quick Commands
```bash
# Help
./scripts/publish_to_docs.sh --help

# Examples
./scripts/examples/comparison_examples.sh

# Compare two specific versions
./scripts/publish_to_docs.sh nzd0021 latest interface.crate-cb67e8e26-20250801011405 interface.crate-d61c2052a-20250725024714
```
