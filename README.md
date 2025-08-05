# CoastSat Shoreline Publication System

Generate interactive, reproducible research publications from CoastSat shoreline analysis data using RO-Crate and Stencila technologies.

## 🚀 Quick Start

### Basic Usage

```bash
# Generate a publication
python src/publication_logic.py aus0001

# Generate + populate crate with content
python src/publication_logic.py aus0001 --populate-crate

# Test with preview (quiet mode)
./tests/test_publication_enhanced.sh aus0001

# Test with detailed output
./tests/test_publication_enhanced.sh aus0001 --verbose
```

### Deploy to GitHub Pages

```bash
# Generate publication and deploy to GitHub Pages
./scripts/publish_to_docs.sh aus0001

# Then commit and push
git add docs/
git commit -m "Publish aus0001 publication" 
git push
```

Enable GitHub Pages in repository settings (source: docs/ folder) and your publication will be live at:
`https://GusEllerm.github.io/CoastSat-shorelinepublication/`

## 📋 Core Features

- **Dynamic Publications**: Executable documents with live code and data
- **RO-Crate Metadata**: Research Object metadata for reproducibility  
- **GitHub Pages Deployment**: One-command publishing to web
- **Version Comparison**: Compare publications across interface versions
- **Clean Output**: Quiet mode by default, verbose for debugging

## 🛠️ Common Commands

| Task | Command |
|------|---------|
| Generate publication | `python src/publication_logic.py [SITE_ID]` |
| Test with preview | `./tests/test_publication_enhanced.sh [SITE_ID]` |
| Deploy to web | `./scripts/publish_to_docs.sh [SITE_ID]` |
| Create GitHub release | `./scripts/create_publication.sh [SITE_ID]` |
| Compare versions | `./tests/test_publication_compare.sh [SITE_ID] [VER1] [VER2]` |

## 💡 Key Options

- `--populate-crate` - Include generated content in the crate
- `--verbose` - Show detailed processing output  
- `--no-open` - Don't auto-open generated HTML
- `-i_crate [VERSION]` - Use specific interface.crate version

## 🏗️ Project Structure

```
src/                    # Core logic
├── publication_logic.py   # Main publication generator
├── crate_builder.py       # RO-Crate system
└── templates/             # Document templates

scripts/                # Automation
├── publish_to_docs.sh     # Deploy to GitHub Pages  
├── create_publication.sh  # Create GitHub releases
└── patch_post_release.py  # Post-release patching

tests/                  # Testing tools
├── test_publication_enhanced.sh   # Main testing
├── test_publication_compare.sh    # Version comparison
└── test_publication_creation.sh   # Release testing

docs/                   # GitHub Pages site (auto-generated)
```

## 📦 Installation

```bash
git clone https://github.com/GusEllerm/CoastSat-shorelinepublication.git
cd CoastSat-shorelinepublication
pip install -r requirements.txt

# For GitHub Pages deployment
npm install -g ro-crate-html-js
```

## 🔧 Requirements

- Python 3.8+
- Stencila CLI
- ro-crate-html-js (for GitHub Pages)
- GitHub CLI (for releases)

## 📖 Template Development

Edit `src/templates/shoreline_publication.smd` to customize publications:

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

## 📞 Contact

- **Author**: Gus Ellerm  
- **Email**: aell854@UoA.auckland.ac.nz
- **GitHub**: [CoastSat-shorelinepublication](https://github.com/GusEllerm/CoastSat-shorelinepublication)

---

*CoastSat Shoreline Publication System - Making coastal research reproducible and accessible*
