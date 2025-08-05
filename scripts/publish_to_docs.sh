#!/bin/bash

# Publication to Docs Script
# Generates a publication with populated crate and creates a GitHub Pages-ready docs/ directory
# Usage: ./scripts/publish_to_docs.sh [SITE_ID]
# Example: ./scripts/publish_to_docs.sh nzd0021

set -e  # Exit on any error

# Check if rochtml is available
if ! command -v rochtml >/dev/null 2>&1; then
    echo "❌ rochtml command not found"
    echo "💡 Please install ro-crate-html-js:"
    echo "   npm install -g ro-crate-html-js"
    exit 1
fi

# Parse arguments
SITE_ID="${1:-nzd0021}"

echo "🚀 Publishing CoastSat publication for site: $SITE_ID"
echo ""

# Step 1: Generate publication with populated crate
echo "📝 Step 1: Generating publication with populated crate..."
./tests/test_publication_enhanced.sh "$SITE_ID" --no-open --populate-crate

if [ $? -ne 0 ]; then
    echo "❌ Failed to generate publication"
    exit 1
fi

echo "✅ Publication generated successfully"
echo ""

# Step 2: Generate RO-Crate HTML preview
echo "🌐 Step 2: Generating RO-Crate HTML preview..."
rochtml publication.crate/ro-crate-metadata.json

if [ $? -ne 0 ]; then
    echo "❌ Failed to generate RO-Crate HTML preview"
    exit 1
fi

echo "✅ RO-Crate HTML preview generated"
echo ""

# Step 3: Prepare docs directory
echo "📁 Step 3: Preparing docs/ directory..."

# Clean existing docs directory
if [ -d "docs/" ]; then
    echo "🧹 Cleaning existing docs/ directory..."
    rm -rf docs/
fi

# Create fresh docs directory
mkdir -p docs/

# Step 4: Copy publication.crate contents to docs/
echo "📦 Step 4: Copying publication crate to docs/..."
cp -r publication.crate/* docs/

echo "✅ Publication crate copied to docs/"
echo ""

# Step 5: Rename ro-crate-preview.html to index.html
echo "🔄 Step 5: Setting up GitHub Pages index..."

if [ -f "docs/ro-crate-preview.html" ]; then
    mv docs/ro-crate-preview.html docs/index.html
    echo "✅ Renamed ro-crate-preview.html to index.html"
else
    echo "⚠️  ro-crate-preview.html not found, checking for alternative names..."
    
    # Check for other possible names
    if [ -f "docs/index.html" ]; then
        echo "✅ index.html already exists"
    elif [ -f "docs/preview.html" ]; then
        mv docs/preview.html docs/index.html
        echo "✅ Renamed preview.html to index.html"
    else
        echo "❌ No suitable HTML preview file found"
        echo "📋 Available HTML files in docs/:"
        ls -la docs/*.html 2>/dev/null || echo "   No HTML files found"
        exit 1
    fi
fi

echo ""

# Step 6: Clean up publication.crate directory
echo "🧹 Step 6: Cleaning up publication.crate directory..."
if [ -d "publication.crate/" ]; then
    rm -rf publication.crate/
    echo "✅ Removed publication.crate/ directory"
else
    echo "ℹ️  publication.crate/ directory not found"
fi

echo ""

# Step 7: Summary and next steps
echo "🎉 GitHub Pages publication ready!"
echo ""
echo "📋 Summary:"
echo "   📄 Publication: docs/shorelinepublication.html"
echo "   🌐 GitHub Pages: docs/index.html (RO-Crate preview)"
echo "   📊 Metadata: docs/ro-crate-metadata.json"
echo "   📁 Site ID: $SITE_ID"
echo ""
echo "🚀 Next steps to publish:"
echo "   1. git add docs/"
echo "   2. git commit -m \"Publish $SITE_ID publication to GitHub Pages\""
echo "   3. git push"
echo "   4. Enable GitHub Pages in repository settings (source: docs/ folder)"
echo ""
echo "🌐 After enabling GitHub Pages, your publication will be available at:"
echo "   https://GusEllerm.github.io/CoastSat-shorelinepublication/"
echo ""
echo "✨ Done!"
