#!/bin/bash

set -e

echo "🧪 Testing Publication Creation Workflow..."
echo ""

# Test 1: Regenerate publication.crate
echo "🏗️  Test 1: Regenerating publication.crate..."
python ../src/crate_builder.py
echo "✅ publication.crate regenerated"

# Test 2: Check if rochtml works
echo ""
echo "🌐 Test 2: Testing HTML preview generation..."
if command -v rochtml >/dev/null 2>&1; then
    rochtml publication.crate/ro-crate-metadata.json
    echo "✅ HTML preview generated successfully"
    ls -la publication.crate/*.html || echo "No HTML files found"
else
    echo "⚠️  rochtml not found, skipping HTML preview"
fi

# Test 3: Test patch script
echo ""
echo "🔧 Test 3: Testing patch functionality..."
test_url="https://github.com/GusEllerm/CoastSat-shorelinepublication/releases/tag/test-$(date +%s)"
python ../scripts/patch_post_release.py "$test_url"
echo "✅ Patch script works"

# Test 4: Create test zip
echo ""
echo "📦 Test 4: Testing zip creation..."
timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
test_zip="test-shoreline-publication-crate-${timestamp}.zip"
zip -r "$test_zip" publication.crate
if [ -f "$test_zip" ]; then
    echo "✅ Zip created successfully: $test_zip"
    echo "📊 Size: $(ls -lh "$test_zip" | awk '{print $5}')"
    rm "$test_zip"
    echo "🧹 Test zip cleaned up"
else
    echo "❌ Failed to create zip"
    exit 1
fi

# Test 5: Check git status
echo ""
echo "📋 Test 5: Checking git status..."
if [[ -n $(git status --porcelain publication.crate) ]]; then
    echo "📝 Changes detected in publication.crate:"
    git status --porcelain publication.crate
else
    echo "ℹ️  No changes in publication.crate"
fi

echo ""
echo "🎉 All tests passed! The publication creation workflow is working."
echo ""
echo "To create an actual release (requires GitHub CLI setup):"
echo "  ./create_publication.sh"
echo ""
