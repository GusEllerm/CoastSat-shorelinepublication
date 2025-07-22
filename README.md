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
│   └── README.md               # Testing documentation
│
├── docs/                        # Documentation
├── publication.crate/           # Generated publication crate (git-ignored)
└── CoastSat/                   # External submodule
```

## 🚀 Quick Start

### Generate a Publication

```bash
# Using the main logic
python src/publication_logic.py aus0001

# Using the backward-compatible wrapper
python publication_crate.py
```

### Run Tests

```bash
# Enhanced testing with auto-preview
tests/test_publication_enhanced.sh aus0001

# Release workflow testing
tests/test_publication_creation.sh
```

### Create GitHub Release

```bash
# Automated release creation
scripts/create_publication.sh aus0001
```

## 📦 Core Components

### **`src/publication_logic.py`**

Main publication generation logic with dual execution modes:

- **Development Mode**: Run from project root to generate publications
- **Webservice Mode**: Run from within publication.crate for dynamic content

### **`src/crate_builder.py`**

RO-Crate generation system that:

- Downloads latest interface.crate from GitHub releases
- Copies templates and logic files from `src/`
- Generates complete publication.crate with metadata

### **`src/templates/shoreline_publication.smd`**

Document template that authors edit to customize publications. Uses Stencila's dynamic document format with executable Python code blocks.

## 🖋️ Author Workflow

To customize the publication template:

1. **Edit the template**: Modify `src/templates/shoreline_publication.smd`
2. **Rebuild the crate**: Run `python src/crate_builder.py`
3. **Test locally**: Run `python src/publication_logic.py [site_id]`
4. **Create release**: Run `scripts/create_publication.sh [site_id]`

### Template Example

```markdown
# My Custom Shoreline Analysis

```python exec
import json
with open('data.json', 'r') as f:
    data = json.load(f)
  
site_id = data['id'] 
print(f"Analysis for site: {site_id}")
```

```

## 🔧 Technical Architecture

- **Stencila 2.4.1**: Dynamic document rendering with executable Python code blocks  
- **RO-Crate Standard**: Metadata and data provenance using ROCrate Python library
- **Dual Execution**: Works both as development tool and webservice component
- **GitHub Integration**: Automated release creation with embedded URLs

## 🌐 Webservice Integration  

The generated `publication.crate/` can be used by webservices:

```python
# Webservice usage example
def generate_publication(site_id, output_path):
    result = subprocess.run([
        "python",
        os.path.join("publication.crate", "publication_logic.py"), 
        site_id,
        "--output", 
        output_path
    ], check=True)
    return output_path
```

The publication.crate is self-contained and portable for deployment.

## 📝 Dependencies

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
