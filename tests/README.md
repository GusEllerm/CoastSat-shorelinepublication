# Tests Documentation

This directory contains testing infrastructure for the CoastSat Shoreline Publication system.

## Test Scripts

### `test_publication_enhanced.sh`
**Purpose**: Comprehensive testing workflow with auto-preview functionality  
**Usage**: `./test_publication_enhanced.sh [SITE_ID] [--no-open]`  

**Features:**
- Complete publication.crate regeneration testing
- Cross-platform auto-browser opening
- Detailed content verification and reporting
- Timeout protection for network operations
- Argument parsing with help system

**Options:**
- `SITE_ID`: Custom site ID (default: `test_site_TIMESTAMP`)
- `--no-open`: Disable automatic browser opening
- `--help`: Show usage information

### `test_publication_creation.sh` 
**Purpose**: Automated workflow testing for release creation  
**Usage**: `./test_publication_creation.sh`

**Features:**
- Tests publication.crate regeneration
- Validates HTML preview generation with rochtml
- Tests patch functionality with mock release URLs
- Comprehensive workflow validation

## Testing Workflow

1. **Clean Environment**: Remove existing publication.crate
2. **Regenerate Crate**: Use `src/crate_builder.py` to create fresh crate
3. **Validate Structure**: Check for required files and metadata
4. **Test Logic**: Execute `src/publication_logic.py` with test site ID
5. **Verify Output**: Validate generated HTML content
6. **Auto-Preview**: Open result in browser (optional)

## Dependencies

- **Python 3.8+**: Required for publication logic
- **Stencila CLI**: Required for document processing
- **ROCrate library**: Required for crate validation
- **Web browser**: For auto-preview functionality

## Cross-Platform Support

Tests are designed to work on:
- **macOS**: Uses `open` command for browser opening
- **Linux**: Uses `xdg-open` command for browser opening  
- **Windows**: Uses `start` command for browser opening

## Integration Testing

Tests validate the complete system including:
- Core publication logic (`src/publication_logic.py`)
- Crate building (`src/crate_builder.py`) 
- Dual execution modes (parent directory vs webservice)
- Template processing and data injection
- Stencila pipeline execution
