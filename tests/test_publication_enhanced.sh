#!/bin/bash

# Enhanced Publication Testing Script
# Supports testing publication generation with optional crate population
# Usage examples:
#   ./tests/test_publication_enhanced.sh nzd0001                              # Basic generation (quiet mode)
#   ./tests/test_publication_enhanced.sh nzd0001 --populate-crate             # Generate and populate crate (quiet mode)
#   ./tests/test_publication_enhanced.sh nzd0001 --populate-crate --no-open   # Populate crate without opening HTML (quiet mode)
#   ./tests/test_publication_enhanced.sh nzd0001 --verbose                    # Show detailed output
#   ./tests/test_publication_enhanced.sh nzd0001 --populate-crate --verbose   # Verbose mode with crate population

set -e  # Exit on any error

# Function to print messages conditionally based on verbose mode
log_info() {
    if [ "$VERBOSE_MODE" = true ]; then
        echo "$@"
    fi
}

# Function to always print important messages
log_important() {
    echo "$@"
}

# Parse arguments
AUTO_OPEN=true
CUSTOM_SITE_ID=""
CUSTOM_INTERFACE_CRATE=""
POPULATE_CRATE=false
VERBOSE_MODE=false
FROM_DATE=""
TO_DATE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --no-open)
            AUTO_OPEN=false
            shift
            ;;
        -i_crate|--interface-crate)
            CUSTOM_INTERFACE_CRATE="$2"
            shift 2
            ;;
        --populate-crate)
            POPULATE_CRATE=true
            shift
            ;;
        --from)
            FROM_DATE="$2"
            shift 2
            ;;
        --to)
            TO_DATE="$2"
            shift 2
            ;;
        -v|--verbose)
            VERBOSE_MODE=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [SITE_ID] [--no-open] [-i_crate VERSION] [--populate-crate] [--from DATE] [--to DATE] [--verbose] [--help]"
            echo "  SITE_ID              Custom site ID (default: test_site_TIMESTAMP)"
            echo "  --no-open            Don't automatically open the HTML file"
            echo "  -i_crate VERSION     Use specific interface.crate release version (default: latest)"
            echo "                       Examples: v1.0.0, v2.1.3, latest"
            echo "  --populate-crate     Populate the crate with generated content and update metadata"
            echo "  --from DATE          Filter data from this date (format: DD-MM-YYYY, e.g., 01-01-1995)"
            echo "  --to DATE            Filter data to this date (format: DD-MM-YYYY, e.g., 31-12-2020)"
            echo "  -v, --verbose        Show detailed output (default: quiet mode)"
            echo "  --help               Show this help message"
            exit 0
            ;;
        *)
            if [ -z "$CUSTOM_SITE_ID" ]; then
                CUSTOM_SITE_ID="$1"
            fi
            shift
            ;;
    esac
done

if [ -z "$CUSTOM_SITE_ID" ]; then
    CUSTOM_SITE_ID="test_site_$(date +%s)"
    log_info "📝 No site ID provided, using default: $CUSTOM_SITE_ID"
else
    log_info "📝 Using provided site ID: $CUSTOM_SITE_ID"
fi

log_info "📦 Using interface.crate version: ${CUSTOM_INTERFACE_CRATE:-latest}"

if [ -n "$FROM_DATE" ]; then
    log_info "📅 Filter data from: $FROM_DATE"
fi

if [ -n "$TO_DATE" ]; then
    log_info "📅 Filter data to: $TO_DATE"
fi

if [ "$POPULATE_CRATE" = true ]; then
    log_info "📁 Will populate crate with generated content"
else
    log_info "📁 Will generate publication in current directory only"
fi

log_info "🧹 Cleaning up old publication.crate..."
if [ -d "publication.crate" ]; then
    rm -rf publication.crate/
    log_info "✅ Removed old publication.crate/"
else
    log_info "ℹ️  No existing publication.crate/ to remove"
fi

# Run crate_builder.py with timeout to avoid hanging indefinitely
if [ -n "$CUSTOM_INTERFACE_CRATE" ]; then
    log_info "🔧 Using custom interface.crate version: $CUSTOM_INTERFACE_CRATE"
    if [ "$VERBOSE_MODE" = false ]; then
        timeout 300 python src/crate_builder.py --interface-crate "$CUSTOM_INTERFACE_CRATE" >/dev/null 2>&1 || {
            log_important "❌ src/crate_builder.py timed out or failed"
            log_important "💡 This might be due to network issues or GitHub API limits"
            exit 1
        }
    else
        timeout 300 python src/crate_builder.py --interface-crate "$CUSTOM_INTERFACE_CRATE" || {
            log_important "❌ src/crate_builder.py timed out or failed"
            log_important "💡 This might be due to network issues or GitHub API limits"
            exit 1
        }
    fi
else
    if [ "$VERBOSE_MODE" = false ]; then
        timeout 300 python src/crate_builder.py >/dev/null 2>&1 || {
            log_important "❌ src/crate_builder.py timed out or failed"
            log_important "💡 This might be due to network issues or GitHub API limits"
            exit 1
        }
    else
        timeout 300 python src/crate_builder.py || {
            log_important "❌ src/crate_builder.py timed out or failed"
            log_important "💡 This might be due to network issues or GitHub API limits"
            exit 1
        }
    fi
fi

if [ $? -eq 0 ]; then
    log_info "✅ publication.crate/ regenerated successfully"
else
    log_important "❌ Failed to regenerate publication.crate/"
    exit 1
fi

log_info ""
log_info "📋 Checking publication.crate contents..."
if [ -f "publication.crate/shoreline_publication.smd" ]; then
    log_info "✅ Template file found in publication.crate/"
    log_info ""
else
    log_important "❌ Template file not found in publication.crate/"
    exit 1
fi

if [ -f "publication.crate/publication_logic.py" ]; then
    log_info "✅ Logic file found in publication.crate/"
else
    log_important "❌ Logic file not found in publication.crate/"
    exit 1
fi

log_info ""
log_important "🚀 Running shoreline publication generation..."
log_info "Using site ID: $CUSTOM_SITE_ID"

# Build command arguments
PUBLICATION_ARGS=("$CUSTOM_SITE_ID")

if [ "$POPULATE_CRATE" = true ]; then
    PUBLICATION_ARGS+=("--populate-crate")
fi

if [ -n "$FROM_DATE" ]; then
    PUBLICATION_ARGS+=("--from" "$FROM_DATE")
fi

if [ -n "$TO_DATE" ]; then
    PUBLICATION_ARGS+=("--to" "$TO_DATE")
fi

if [ "$POPULATE_CRATE" = true ]; then
    log_info "📁 Running with --populate-crate flag..."
    if [ "$VERBOSE_MODE" = false ]; then
        python src/publication_logic.py "${PUBLICATION_ARGS[@]}" >/dev/null 2>&1
    else
        python src/publication_logic.py "${PUBLICATION_ARGS[@]}"
    fi
else
    if [ "$VERBOSE_MODE" = false ]; then
        python src/publication_logic.py "${PUBLICATION_ARGS[@]}" >/dev/null 2>&1
    else
        python src/publication_logic.py "${PUBLICATION_ARGS[@]}"
    fi
fi

if [ -f "shorelinepublication.html" ]; then
    log_important ""
    log_important "✅ HTML publication generated successfully!"
    log_important "📊 File size: $(ls -lh shorelinepublication.html | awk '{print $5}')"
    log_important "📅 Generated: $(date)"
    log_important "🆔 Site ID used: $CUSTOM_SITE_ID"
    
    if [ "$POPULATE_CRATE" = true ]; then
        log_important "📁 Crate populated with generated content"
        if [ -f "publication.crate/shorelinepublication.html" ] && [ -f "publication.crate/DNF_eval.json" ]; then
            log_info "   ✅ HTML file: publication.crate/shorelinepublication.html"
            log_info "   ✅ DNF eval: publication.crate/DNF_eval.json"
            if [ -f "publication.crate/cached_shoreline.geojson" ] && [ -f "publication.crate/cached_primary_result.geojson" ]; then
                log_info "   ✅ Cached data files referenced in metadata"
            fi
        else
            log_important "   ⚠️  Some crate files may be missing"
        fi
    fi
    
    log_important ""
    log_important "🌐 To view the result:"
    log_important "   file://$(pwd)/shorelinepublication.html"
    log_important ""
    
    if [ "$AUTO_OPEN" = true ]; then
        log_info "🚀 Opening HTML file automatically..."
        if command -v open >/dev/null 2>&1; then
            open "shorelinepublication.html"
            log_info "✅ Opened in default browser"
        elif command -v xdg-open >/dev/null 2>&1; then
            xdg-open "shorelinepublication.html"
            log_info "✅ Opened in default browser"
        elif command -v start >/dev/null 2>&1; then
            start "shorelinepublication.html"
            log_info "✅ Opened in default browser"
        else
            log_info "⚠️  Could not auto-open. Please open manually:"
            log_info "   file://$(pwd)/shorelinepublication.html"
        fi
    else
        log_info "ℹ️  Auto-open disabled. Open manually if desired."
    fi
    log_important ""
    log_important "🎉 Test completed successfully!"
else
    log_important "❌ Failed to generate HTML publication"
    exit 1
fi
