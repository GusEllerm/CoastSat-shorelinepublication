# CoastSat Shoreline Publication System

A dynamic publication system for CoastSat shoreline analysis data that creates interactive, reproducible research publications using RO-Crate and Stencila technologies.

## 🏗️ Project Structure

```
CoastSat-shorelinepublication/
├── src/                         # Core production code
│   ├── publication_logic.py     # Main publication generation logic
│   ├── crate_builder.py         # RO-Crate generation system
│   ├── templates/               # Document templates
│   │   └── shoreline_publication.smd
│   └── __init__.py             # Package initialization
│
├── scripts/                     # Automation scripts
│   ├── create_publication.sh    # Automated GitHub release creation
│   ├── patch_post_release.py    # Post-release metadata patching
│   └── README.md               # Scripts documentation
│
├── tests/                       # Testing infrastructure
│   ├── test_publication_enhanced.sh  # Comprehensive testing
│   ├── test_publication_creation.sh  # Release workflow testing
│   ├── test_publication_compare.sh   # Version comparison testing
│   └── README.md               # Testing documentation
│
├── docs/                        # Documentation
├── publication.crate/           # Generated publication crate (git-ignored)
└── CoastSat/                   # External submodule
```

## 🚀 Quick Start

### Generate a Publication

```bash
# Generate publication in current directory
python src/publication_logic.py aus0001

# Generate publication AND populate the crate with generated content
python src/publication_logic.py aus0001 --populate-crate

# Using the backward-compatible wrapper
python publication_crate.py
```

### Run Tests

```bash
# Enhanced testing with auto-preview (quiet mode by default)
tests/test_publication_enhanced.sh aus0001

# Show detailed output during testing
tests/test_publication_enhanced.sh aus0001 --verbose

# Generate and populate crate (quiet mode)
tests/test_publication_enhanced.sh aus0001 --populate-crate

# Generate and populate crate with detailed output
tests/test_publication_enhanced.sh aus0001 --populate-crate --verbose
```

> **Note**: Tests run in quiet mode by default for clean output. Use `--verbose` for detailed debugging information.

```bash
# Release workflow testing
tests/test_publication_creation.sh

# Compare different interface.crate versions
tests/test_publication_compare.sh aus0001 latest interface.crate-d61c2052a-20250725024714
```

### Advanced Options

#### Crate Population

Transform a "headless" publication crate into a complete archive with actual generated content:

```bash
# Generate publication and populate the crate
python src/publication_logic.py nzd0001 --populate-crate
```

**What `--populate-crate` does:**

- ✅ **Generates** the dynamic publication (HTML + DNF_eval.json)
- ✅ **Copies** both files to the `publication.crate/` directory
- ✅ **Updates** RO-Crate metadata to reference the actual generated files
- ✅ **Preserves** all existing crate structure and relationships

**Use cases:**

- **Static Archival**: Create complete publication archives for long-term storage
- **Content Distribution**: Package publications with all generated content included
- **Metadata Validation**: Ensure crate metadata accurately reflects generated outputs
- **Webservice Preparation**: Pre-populate crates for deployment scenarios

**Before `--populate-crate`:**

```
publication.crate/
├── shoreline_publication.smd    # Template only
├── narrative_zoning.py          # Logic files
├── publication_logic.py     
└── ro-crate-metadata.json       # Metadata pointing to "potential" outputs
```

**After `--populate-crate`:**

```
publication.crate/
├── shoreline_publication.smd    # Template
├── shorelinepublication.html    # ✨ Generated HTML publication
├── DNF_eval.json                # ✨ Evaluated dynamic narrative document
├── narrative_zoning.py          # Logic files  
├── publication_logic.py
└── ro-crate-metadata.json       # ✨ Updated metadata referencing actual files
```

#### Output Verbosity Control

By default, the testing script runs in **quiet mode** showing only essential information for a clean user experience. Use the `--verbose` flag to see detailed processing output for debugging:

```bash
# Quiet mode (default) - clean output with essential information only
tests/test_publication_enhanced.sh aus0001

# Verbose mode - detailed output for debugging and development
tests/test_publication_enhanced.sh aus0001 --verbose

# Quiet mode with crate population
tests/test_publication_enhanced.sh aus0001 --populate-crate

# Verbose mode with crate population for detailed monitoring
tests/test_publication_enhanced.sh aus0001 --populate-crate --verbose
```

**Quiet Mode Output** (8 essential lines):
```
🚀 Running shoreline publication generation...
✅ HTML publication generated successfully!
📊 File size: 1.0M
📅 Generated: Tue Aug  5 11:29:13 NZST 2025
🆔 Site ID used: aus0001
🌐 To view the result: file:///path/to/shorelinepublication.html
🎉 Test completed successfully!
```

**Verbose Mode Output** (100+ lines with detailed processing information):
- Complete Stencila conversion logs
- File operations and path information  
- Detailed error diagnostics
- Step-by-step processing status

#### Custom Interface.crate Version

By default, the system downloads the latest interface.crate release. You can specify a specific version using the `--interface-crate` option:

```bash
# Use a specific interface.crate version (quiet mode)
tests/test_publication_enhanced.sh aus0001 -i_crate interface.crate-cb67e8e26-20250801011405

# Use specific version with detailed output
tests/test_publication_enhanced.sh aus0001 -i_crate interface.crate-cb67e8e26-20250801011405 --verbose

# Use second-to-latest version (quiet mode)
tests/test_publication_enhanced.sh aus0001 -i_crate interface.crate-d61c2052a-20250725024714

# Explicitly use latest (default behavior) with verbose output
tests/test_publication_enhanced.sh aus0001 -i_crate latest --verbose

# Combine with other options (no auto-open, verbose output)
tests/test_publication_enhanced.sh aus0001 --no-open -i_crate interface.crate-d61c2052a-20250725024714 --verbose
```

**Direct crate_builder.py usage:**

```bash
# Use custom interface.crate version directly
python src/crate_builder.py --interface-crate interface.crate-cb67e8e26-20250801011405

# Show available options
python src/crate_builder.py --help
```

**Finding Available Versions:**

```bash
# List available interface.crate releases
curl -s "https://api.github.com/repos/GusEllerm/CoastSat-interface.crate/releases" | grep '"tag_name"' | head -10
```

#### Publication Version Comparison

Compare publications generated with different interface.crate versions side-by-side:

```bash
# Compare latest vs specific version
tests/test_publication_compare.sh aus0001 latest interface.crate-d61c2052a-20250725024714

# Compare two specific versions
tests/test_publication_compare.sh nzd0001 interface.crate-cb67e8e26-20250801011405 interface.crate-d61c2052a-20250725024714

# Generate comparison without auto-opening
tests/test_publication_compare.sh aus0001 latest interface.crate-d61c2052a-20250725024714 --no-open

# Use custom output directory
tests/test_publication_compare.sh aus0001 latest interface.crate-d61c2052a-20250725024714 --output-dir my_comparison
```

### Create GitHub Release

```bash
# Automated release creation
scripts/create_publication.sh aus0001
```

## 📦 Core Components

### **`src/publication_logic.py`**

Main publication generation logic with dual execution modes and crate population capabilities:

- **Development Mode**: Run from project root to generate publications
- **Webservice Mode**: Run from within publication.crate for dynamic content
- **Crate Population**: Use `--populate-crate` to transform headless crates into complete archives

**Key Features:**

- Dynamic document generation using Stencila pipeline
- Site-specific data integration via `data.json`
- RO-Crate metadata management and file association
- Dual output modes: standalone generation vs. crate population

### **`src/crate_builder.py`**

RO-Crate generation system that:

- Downloads interface.crate from GitHub releases (latest or specific version)
- Copies templates and logic files from `src/`
- Generates complete publication.crate with metadata
- Supports version pinning with `--interface-crate` option

### **`src/templates/shoreline_publication.smd`**

Document template that authors edit to customize publications. Uses Stencila's dynamic document format with executable Python code blocks.

## 🖋️ Author Workflow

To customize the publication template:

1. **Edit the template**: Modify `src/templates/shoreline_publication.smd`
2. **Rebuild the crate**: Run `python src/crate_builder.py`
3. **Test locally**: Run `python src/publication_logic.py [site_id]`
4. **Populate crate** (optional): Run `python src/publication_logic.py [site_id] --populate-crate`
5. **Create release**: Run `scripts/create_publication.sh [site_id]`

### Publication Modes

**Development/Testing Mode:**

```bash
# Generate in current directory for testing
python src/publication_logic.py nzd0001
```

**Production/Archive Mode:**

```bash
# Generate AND populate the crate for deployment
python src/publication_logic.py nzd0001 --populate-crate
```

## Template Development

The `shoreline_publication.smd` template supports:

- **Markdown**: Standard markdown formatting
- **Code Blocks**: `python exec` for executable code
- **Data Access**: Site data available via `data.json` & interface.crate manifest
- **Stencila Features**: Flow based node types for procedural content.

Example template structure:

```markdown
---
title: "Shoreline Analysis for {site_id}"
---

# Site Analysis Report

```python exec
import json
with open('data.json', 'r') as f:
    data = json.load(f)
site_id = data['id']
```

Analyzing site **{site_id}**...

```

## Requirements

- Python 3.8+
- Stencila CLI
- Required Python packages: `pandas`, `rocrate`, `requests`

## Installation

```bash
git clone https://github.com/GusEllerm/CoastSat-shorelinepublication.git
cd CoastSat-shorelinepublication
pip install -r requirements.txt
```

## Contact

- Author: Gus Ellerm
- Email: aell854@UoA.auckland.ac.nz
- Project Link: [https://github.com/GusEllerm/CoastSat-shorelinepublication](https://github.com/GusEllerm/CoastSat-shorelinepublication)

## Status

🚀 **Active Development** - Core functionality complete, template development ongoing.

---

*Last updated: August 2025*
