# CoastSat Shoreline Publication

A dynamic publication system that generates interactive HTML reports from CoastSat shoreline analysis data using Stencila and RO-Crate standards.

## Overview

This repository contains a publication crate system that can generate dynamic, reproducible shoreline analysis publications for individual sites. The system uses:

- **Stencila**: For dynamic document rendering with executable code blocks
- **RO-Crate**: For metadata and data provenance 
- **Python**: For data processing and publication logic
- **HTML**: For final publication output

## Project Structure

```
CoastSat-shorelinepublication/
├── shoreline_publication.smd          # Main template (edit this)
├── shorelinepublication_logic.py      # Publication generation logic
├── publication_crate.py               # Creates publication.crate
├── test_publication_enhanced.sh       # Full test workflow script
├── publication.crate/                 # Generated publication crate
│   ├── shoreline_publication.smd      # Template copy
│   ├── shorelinepublication_logic.py  # Logic copy  
│   ├── ro-crate-metadata.json         # RO-Crate metadata
│   └── interface.crate/               # CoastSat workflow data
└── data/                              # Downloaded data files
```

## Quick Start

### 1. Generate a Publication

```bash
# Basic usage - generates publication for a site
./test_publication_enhanced.sh my_site_id

# The script will:
# - Clean old publication.crate
# - Regenerate fresh publication.crate 
# - Run Stencila pipeline
# - Open result in browser
```

### 2. Edit the Template

Edit `shoreline_publication.smd` in the root directory with your content:

```markdown
# My Shoreline Analysis

```python exec
import json

# Load site data
with open('data.json', 'r') as f:
    data = json.load(f)

site_id = data['id']
print(f"Analyzing site: {site_id}")
```

Analysis results for site {site_id}...
```

### 3. Advanced Usage

```bash
# Don't auto-open browser
./test_publication_enhanced.sh my_site --no-open

# Use timestamp-based ID
./test_publication_enhanced.sh

# Get help
./test_publication_enhanced.sh --help
```

## Webservice Integration

The generated `publication.crate/` can be used by webservices:

```python
def run_stencila_pipeline(site_id, unique_id):
    final_path = f"{TMP_DIR}/{unique_id}.html"
    subprocess.run([
        "python",
        os.path.join(PUBLICATION_CRATE, "shorelinepublication_logic.py"),
        site_id,
        "--output",
        final_path
    ], check=True)
    return f"{unique_id}.html"
```

## Development Workflow

1. **Edit Template**: Modify `shoreline_publication.smd` 
2. **Test Changes**: Run `./test_publication_enhanced.sh test_site`
3. **View Results**: HTML opens automatically in browser
4. **Deploy**: Use generated `publication.crate/` in production

## Key Features

- ✅ **Dual Execution Modes**: Works from parent directory or inside publication.crate
- ✅ **Auto-Detection**: Automatically detects execution context
- ✅ **Cross-Platform**: Works on macOS, Linux, Windows
- ✅ **Webservice Ready**: Can be called by web applications
- ✅ **Dynamic Content**: Executable Python blocks in templates
- ✅ **Data Integration**: Automatic site data loading from JSON
- ✅ **Auto-Preview**: Opens generated HTML in browser
- ✅ **RO-Crate Compliant**: Full metadata and provenance tracking

## Template Development

The `shoreline_publication.smd` template supports:

- **Markdown**: Standard markdown formatting
- **Python Code Blocks**: `python exec` for executable code
- **Data Access**: Site data available via `data.json`
- **Variables**: Use computed values in text sections
- **Stencila Features**: Full dynamic document capabilities

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

*Last updated: July 2025*
