#!/bin/bash

set -e  # Exit on any error

# Parse arguments
AUTO_OPEN=true
CUSTOM_SITE_ID=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --no-open)
            AUTO_OPEN=false
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [SITE_ID] [--no-open] [--help]"
            echo "  SITE_ID    Custom site ID (default: test_site_TIMESTAMP)"
            echo "  --no-open  Don't automatically open the HTML file"
            echo "  --help     Show this help message"
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

# Set default site ID if none provided
if [ -z "$CUSTOM_SITE_ID" ]; then
    CUSTOM_SITE_ID="test_site_$(date +%s)"
    echo "📝 No site ID provided, using default: $CUSTOM_SITE_ID"
else
    echo "📝 Using provided site ID: $CUSTOM_SITE_ID"
fi

echo "🧹 Cleaning up old publication.crate..."
if [ -d "publication.crate" ]; then
    rm -rf publication.crate/
    echo "✅ Removed old publication.crate/"
else
    echo "ℹ️  No existing publication.crate/ to remove"
fi

echo ""
echo "🏗️  Regenerating publication.crate..."
echo "⏳ This may take a while as it downloads interface.crate..."

# Run publication_crate.py with timeout to avoid hanging indefinitely
timeout 300 python publication_crate.py || {
    echo "❌ publication_crate.py timed out or failed"
    echo "💡 This might be due to network issues or GitHub API limits"
    exit 1
}

if [ $? -eq 0 ]; then
    echo "✅ publication.crate/ regenerated successfully"
else
    echo "❌ Failed to regenerate publication.crate/"
    exit 1
fi

echo ""
echo "📋 Checking publication.crate contents..."
if [ -f "publication.crate/shoreline_publication.smd" ]; then
    echo "✅ Template file found in publication.crate/"
    echo "Template content:"
    cat "publication.crate/shoreline_publication.smd" | sed 's/^/   │ /'
    echo ""
else
    echo "❌ Template file not found in publication.crate/"
    exit 1
fi

if [ -f "publication.crate/shorelinepublication_logic.py" ]; then
    echo "✅ Logic file found in publication.crate/"
else
    echo "❌ Logic file not found in publication.crate/"
    exit 1
fi

echo ""
echo "🚀 Running shoreline publication generation..."
echo "Using site ID: $CUSTOM_SITE_ID"

python shorelinepublication_logic.py "$CUSTOM_SITE_ID"

if [ -f "shorelinepublication.html" ]; then
    echo ""
    echo "✅ HTML publication generated successfully!"
    echo "📊 File size: $(ls -lh shorelinepublication.html | awk '{print $5}')"
    echo "📅 Generated: $(date)"
    echo "🆔 Site ID used: $CUSTOM_SITE_ID"
    echo ""
    echo "🔍 Content verification:"
    CONTENT_COUNT=$(grep -c "testing" shorelinepublication.html || echo "0")
    if [ "$CONTENT_COUNT" -gt 0 ]; then
        echo "✅ Found $CONTENT_COUNT instances of 'testing' in HTML"
        echo "🔍 Preview of content:"
        grep -A2 -B2 "testing" shorelinepublication.html | head -5 | sed 's/^/   │ /'
    else
        echo "⚠️  No 'testing' content found in HTML"
        echo "🔍 HTML structure:"
        grep -E "(stencila-|<title>|<h1>)" shorelinepublication.html | head -3 | sed 's/^/   │ /'
    fi
    echo ""
    echo "🌐 To view the result:"
    echo "   file://$(pwd)/shorelinepublication.html"
    echo ""
    
    if [ "$AUTO_OPEN" = true ]; then
        echo "🚀 Opening HTML file automatically..."
        if command -v open >/dev/null 2>&1; then
            open "shorelinepublication.html"
            echo "✅ Opened in default browser"
        elif command -v xdg-open >/dev/null 2>&1; then
            xdg-open "shorelinepublication.html"
            echo "✅ Opened in default browser"
        elif command -v start >/dev/null 2>&1; then
            start "shorelinepublication.html"
            echo "✅ Opened in default browser"
        else
            echo "⚠️  Could not auto-open. Please open manually:"
            echo "   file://$(pwd)/shorelinepublication.html"
        fi
    else
        echo "ℹ️  Auto-open disabled. Open manually if desired."
    fi
    echo ""
    echo "🎉 Test completed successfully!"
else
    echo "❌ Failed to generate HTML publication"
    exit 1
fi
