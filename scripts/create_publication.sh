#!/bin/bash

set -e

echo "🚀 Creating CoastSat Shoreline Publication Release..."
echo ""

# Regenerate publication.crate
echo "🏗️  Regenerating publication.crate..."
python src/crate_builder.py

# Generate HTML preview of the crate
echo "🌐 Generating HTML preview..."
if command -v rochtml >/dev/null 2>&1; then
    rochtml publication.crate/ro-crate-metadata.json
    echo "✅ HTML preview generated"
else
    echo "⚠️  rochtml not found, skipping HTML preview"
fi

# Create timestamp for release
timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
crate_zip="shoreline-publication-crate-${timestamp}.zip"

echo ""
echo "📋 Checking for changes..."

# Commit & push changes if any
if [[ -n $(git status --porcelain publication.crate) ]]; then
    commit_msg="Publish updated shoreline publication crate ($timestamp)"
    echo "📝 Committing changes: $commit_msg"
    git add publication.crate
    git commit -m "$commit_msg"
    
    echo "🔄 Pushing to main branch..."
    git push origin main
    echo "✅ Changes committed and pushed"
else
    echo "ℹ️  No changes in publication.crate to commit."
fi

echo ""
echo "🏷️  Creating GitHub release..."

# Create a release
release_tag="shoreline-crate-$timestamp"
gh release create "$release_tag" \
  --title "Shoreline Publication Crate - $timestamp" \
  --notes "Auto-generated release of the CoastSat shoreline publication crate.

🌊 **CoastSat Shoreline Publication Crate**
📅 Generated: $(date)
🔧 Contains: Dynamic publication templates, logic, and metadata

## Usage
\`\`\`bash
# Download and extract
wget https://github.com/GusEllerm/CoastSat-shorelinepublication/releases/download/$release_tag/$crate_zip
unzip $crate_zip

# Run publication
python publication.crate/shorelinepublication_logic.py site_id --output result.html
\`\`\`" \
  --target main

echo "✅ GitHub release created: $release_tag"

# Get release URL
echo "🔗 Getting release URL..."
release_url=$(gh release view "$release_tag" --json url -q .url)
echo "📍 Release URL: $release_url"

# Patch the crate with release URL
echo ""
echo "🔧 Patching publication.crate with release URL..."
python scripts/patch_post_release.py "$release_url"

# Regenerate HTML after patching
if command -v rochtml >/dev/null 2>&1; then
    echo "🌐 Regenerating HTML preview with updated metadata..."
    rochtml publication.crate/ro-crate-metadata.json
fi

# Create zip package
echo "📦 Creating release package..."
zip -r "$crate_zip" publication.crate

# Upload the zip to the release
echo "⬆️  Uploading package to release..."
gh release upload "$release_tag" "$crate_zip" --clobber

# Update release notes with final URL
gh release edit "$release_tag" --notes "Auto-generated release of the CoastSat shoreline publication crate.

🌊 **CoastSat Shoreline Publication Crate**
📅 Generated: $(date)
🔧 Contains: Dynamic publication templates, logic, and metadata
� Release URL: $release_url

## Usage
\`\`\`bash
# Download and extract  
wget https://github.com/GusEllerm/CoastSat-shorelinepublication/releases/download/$release_tag/$crate_zip
unzip $crate_zip

# Run publication
python publication.crate/shorelinepublication_logic.py site_id --output result.html
\`\`\`

## Contents
- \`shoreline_publication.smd\` - Dynamic publication template
- \`shorelinepublication_logic.py\` - Publication generation logic  
- \`ro-crate-metadata.json\` - RO-Crate metadata
- \`interface.crate/\` - CoastSat workflow data and metadata"

echo ""
echo "🧹 Cleaning up temporary files..."
rm "$crate_zip"

echo ""
echo "🎉 Publication crate release completed successfully!"
echo "📍 Release: $release_url"
echo "🏷️  Tag: $release_tag"
echo ""