# Scripts Documentation

This directory contains automation and utility scripts for the CoastSat Shoreline Publication system.

## Scripts Overview

### `create_publication.sh`
**Purpose**: Automated GitHub release creation for publication.crate  
**Usage**: `./create_publication.sh [SITE_ID]`  
**Description**: Complete workflow that regenerates publication.crate, creates GitHub releases, and embeds release URLs into the crate metadata.

**Key Features:**
- Regenerates publication.crate using `src/crate_builder.py`
- Creates timestamped GitHub releases with ZIP downloads
- Patches crate metadata with release URLs using `patch_post_release.py`
- Handles git operations and error recovery

### `publish_to_docs.sh` (Enhanced)
**Purpose**: Enhanced GitHub Pages deployment with modern landing page, version comparison, and robust error handling  
**Usage**: `./publish_to_docs.sh [SITE_ID] [INTERFACE_CRATE_VERSION] [COMPARISON_VERSION_1] [COMPARISON_VERSION_2]`  
**Description**: Comprehensive workflow for creating publication-ready GitHub Pages deployment with enhanced UX and version comparison features.

**Enhanced Features:**
- **Modern Landing Page**: Responsive HTML5 landing page with CSS styling and metadata display
- **Version Comparison**: Side-by-side comparison of publications generated with different interface.crate versions
- **Enhanced Help System**: Comprehensive usage documentation with examples and common scenarios
- **Robust Error Handling**: Dependency validation, graceful failure handling, and helpful error messages
- **Interactive Experience**: Progress indicators, confirmation prompts, and detailed feedback
- **Fallback Support**: Automatic handling of missing files with intelligent fallbacks
- **Metadata Integration**: Dynamic site ID, interface.crate version, and timestamp display

**Version Comparison Configuration:**
The script generates a comparison between two different interface.crate versions, which can be configured in several ways:

1. **Command Line Arguments**: 
   ```bash
   ./scripts/publish_to_docs.sh nzd0021 latest latest interface.crate-cb67e8e26-20250801011405
   ```

2. **Environment Variables**:
   ```bash
   COMPARISON_V1=latest COMPARISON_V2=interface.crate-d61c2052a-20250725024714 ./scripts/publish_to_docs.sh nzd0021
   ```

3. **Defaults**: If not specified, uses `latest` vs `interface.crate-d61c2052a-20250725024714`

**Available Interface.crate Versions:**
- `latest` - Most recent GitHub release
- `interface.crate-cb67e8e26-20250801011405` - August 1, 2025 release
- `interface.crate-d61c2052a-20250725024714` - July 25, 2025 release
- Any tag from [interface.crate releases](https://github.com/GusEllerm/CoastSat-interface.crate/releases)

**Output Structure:**
```
docs/
├── index.html                    # Enhanced responsive landing page
├── shorelinepublication.html     # Main shoreline publication
├── shorelinepublication-v1.html  # First version for comparison
├── shorelinepublication-v2.html  # Second version for comparison
├── version-comparison.html       # Side-by-side comparison interface
├── ro-crate-preview.html         # RO-Crate browser
├── ro-crate-metadata.json        # Publication metadata
└── [other publication.crate files]
```

**Examples:**
```bash
# Basic usage with default comparison (latest vs July 2025)
./scripts/publish_to_docs.sh nzd0001

# Custom comparison versions via command line
./scripts/publish_to_docs.sh nzd0001 latest latest interface.crate-cb67e8e26-20250801011405

# Environment variable override
COMPARISON_V1=interface.crate-cb67e8e26-20250801011405 COMPARISON_V2=interface.crate-d61c2052a-20250725024714 ./scripts/publish_to_docs.sh nzd0001

# Australian site with specific versions
./scripts/publish_to_docs.sh aus0001 interface.crate-cb67e8e26-20250801011405 latest interface.crate-d61c2052a-20250725024714

# Get comprehensive help
./scripts/publish_to_docs.sh --help

# View examples
./scripts/examples/comparison_examples.sh
```
./scripts/publish_to_docs.sh --help
```

**GitHub Pages Setup:**
1. Run the script: `./scripts/publish_to_docs.sh nzd0022`
2. Commit the docs/ directory: `git add docs/ && git commit -m "Publish nzd0022 shoreline publication"`
3. Push to GitHub: `git push`
4. Enable GitHub Pages in repository settings (source: docs/ folder)
5. Your publication will be available at the GitHub Pages URL with enhanced landing page

### `patch_post_release.py`
**Purpose**: Add release URLs to publication.crate metadata post-release  
**Usage**: `python patch_post_release.py <RELEASE_URL>`  
**Description**: Updates the mainEntity URL in the RO-Crate metadata to point to the GitHub release.

**Key Features:**
- Loads existing publication.crate using ROCrate library
- Updates mainEntity URL property
- Comprehensive error handling and logging
- Validates crate structure before patching

## Dependencies

- **GitHub CLI (gh)**: Required for `create_publication.sh` to create releases
- **ro-crate-html-js**: Optional for `publish_to_docs.sh` to generate additional RO-Crate HTML previews
  ```bash
  npm install -g ro-crate-html-js
  ```
- **ROCrate Python library**: Required for `patch_post_release.py` to manipulate crate metadata
- **Git**: Required for version control operations
- **Bash Shell**: Required for enhanced script functionality (macOS/Linux)
- **Basic CLI Tools**: `cp`, `mkdir`, `rm`, `date` (standard on most systems)

## Enhanced Features (publish_to_docs.sh)

The enhanced `publish_to_docs.sh` script provides a comprehensive publication deployment experience:

### Landing Page Features
- **Responsive Design**: Works seamlessly on desktop and mobile devices
- **Modern Styling**: Clean, professional appearance with hover effects and gradients
- **Metadata Display**: Dynamic site ID, interface.crate version, and generation timestamp
- **Navigation**: Direct links to shoreline publication and RO-Crate browser
- **Accessibility**: Semantic HTML with proper structure and styling

### Error Handling
- **Dependency Validation**: Checks for required files and directories
- **Graceful Failures**: Provides helpful error messages with resolution suggestions
- **Fallback Creation**: Automatically creates missing files when possible
- **User Confirmation**: Interactive prompts for destructive operations

### User Experience
- **Progress Indicators**: Clear step-by-step progress with emojis and descriptions
- **Comprehensive Help**: Detailed usage documentation with examples
- **Validation**: Input validation for site IDs and parameters
- **Clean Output**: Well-formatted terminal output with clear sections

## Authentication

GitHub CLI must be authenticated:
```bash
gh auth login
```

For permission issues, scripts may need to be run with `sudo`:
```bash
sudo ./create_publication.sh aus0001
```

## Integration

These scripts integrate with the main publication system located in `src/`:
- Uses `src/crate_builder.py` to generate publication.crate
- Operates on crates generated by `src/publication_logic.py`
- Maintains compatibility with the dual execution mode system
