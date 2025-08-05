#!/bin/bash

# Publication to Docs Script for CoastSat Shoreline Publications
# Generates a publication with populated crate and creates a GitHub Pages-ready docs/ directory
# Usage: ./scripts/publish_to_docs.sh [SITE_ID] [INTERFACE_CRATE_VERSION] [COMPARISON_VERSION_1] [COMPARISON_VERSION_2]
# Examples: 
#   ./scripts/publish_to_docs.sh nzd0021
#   ./scripts/publish_to_docs.sh nzd0021 latest
#   ./scripts/publish_to_docs.sh nzd0021 latest latest interface.crate-d61c2052a-20250725024714
#   ./scripts/publish_to_docs.sh aus0001-0001 interface.crate-d61c2052a-20250725024714 latest interface.crate-cb67e8e26-20250801011405

set -e  # Exit on any error

# Check for help flag
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "CoastSat Shoreline Publication GitHub Pages Publisher"
    echo ""
    echo "Usage: ./scripts/publish_to_docs.sh [SITE_ID] [INTERFACE_CRATE_VERSION] [COMPARISON_VERSION_1] [COMPARISON_VERSION_2]"
    echo ""
    echo "Arguments:"
    echo "  SITE_ID                  Site ID to generate publication for (default: nzd0021)"
    echo "  INTERFACE_CRATE_VERSION  Interface.crate version to use (default: latest)"
    echo "  COMPARISON_VERSION_1     First version for comparison (default: latest)"
    echo "  COMPARISON_VERSION_2     Second version for comparison (default: interface.crate-d61c2052a-20250725024714)"
    echo ""
    echo "Environment Variables:"
    echo "  COMPARISON_V1            Override first comparison version"
    echo "  COMPARISON_V2            Override second comparison version"
    echo ""
    echo "Examples:"
    echo "  ./scripts/publish_to_docs.sh                                    # Use all defaults"
    echo "  ./scripts/publish_to_docs.sh nzd0021                           # Specific site, latest version"
    echo "  ./scripts/publish_to_docs.sh aus0001-0001 latest               # Australian site, latest version"
    echo "  ./scripts/publish_to_docs.sh nzd0021 latest latest interface.crate-cb67e8e26-20250801011405"
    echo "  COMPARISON_V1=latest COMPARISON_V2=interface.crate-cb67e8e26-20250801011405 ./scripts/publish_to_docs.sh nzd0021"
    echo ""
    echo "Available Interface.crate Versions:"
    echo "  • latest                                    (most recent release)"
    echo "  • interface.crate-cb67e8e26-20250801011405  (August 1, 2025 release)"
    echo "  • interface.crate-d61c2052a-20250725024714  (July 25, 2025 release)"
    echo "  • Any tag from: https://github.com/GusEllerm/CoastSat-interface.crate/releases"
    echo ""
    echo "Requirements:"
    echo "  - ro-crate-html-js: npm install -g ro-crate-html-js"
    echo ""
    echo "Output:"
    echo "  Creates docs/ directory with GitHub Pages-ready content including:"
    echo "  - index.html (landing page)"
    echo "  - shorelinepublication.html (interactive publication)"
    echo "  - ro-crate-preview.html (metadata browser)"
    echo "  - version-comparison.html (side-by-side comparison)"
    echo "  - ro-crate-metadata.json (research object metadata)"
    echo ""
    echo "After running, commit and push to deploy:"
    echo "  git add docs/ && git commit -m \"Publish [SITE_ID]\" && git push"
    exit 0
fi

# Check if rochtml is available
if ! command -v rochtml >/dev/null 2>&1; then
    echo "❌ rochtml command not found"
    echo "💡 Please install ro-crate-html-js:"
    echo "   npm install -g ro-crate-html-js"
    exit 1
fi

# Parse arguments
SITE_ID="${1:-nzd0021}"
INTERFACE_CRATE_VERSION="${2:-latest}"

# Parse comparison versions - can be overridden by environment variables or command line
COMPARISON_VERSION_1="${COMPARISON_V1:-${3:-latest}}"
COMPARISON_VERSION_2="${COMPARISON_V2:-${4:-interface.crate-d61c2052a-20250725024714}}"

echo "🚀 Publishing CoastSat shoreline publication for site: $SITE_ID"
echo "Using interface.crate version: $INTERFACE_CRATE_VERSION"
echo "Comparison versions: $COMPARISON_VERSION_1 vs $COMPARISON_VERSION_2"
echo ""

# Step 1: Build interface.crate with specified version (if the project supports this)
echo "📦 Step 1: Building interface.crate..."
if [ "$INTERFACE_CRATE_VERSION" = "latest" ]; then
    echo "Using latest interface.crate version"
else
    echo "Using interface.crate version: $INTERFACE_CRATE_VERSION"
    # Note: Add interface.crate version management if the shoreline project supports it
fi

echo "✅ Interface.crate ready"
echo ""

# Step 2: Generate publication with populated crate
echo "📝 Step 2: Generating shoreline publication with populated crate..."
./tests/test_publication_enhanced.sh "$SITE_ID" --no-open --populate-crate --interface-crate "$INTERFACE_CRATE_VERSION"

if [ $? -ne 0 ]; then
    echo "❌ Failed to generate publication"
    exit 1
fi

echo "✅ Shoreline publication generated successfully"
echo ""

# Step 3: Generate RO-Crate HTML preview
echo "🌐 Step 3: Generating RO-Crate HTML preview..."

# Try to generate RO-Crate HTML preview with timeout
if timeout 30 rochtml publication.crate/ro-crate-metadata.json >/dev/null 2>&1; then
    echo "✅ RO-Crate HTML preview generated successfully"
else
    echo "⚠️  rochtml command timed out or failed"
    echo "💡 Continuing without RO-Crate HTML preview"
    echo "📝 You can generate it manually later with: rochtml publication.crate/ro-crate-metadata.json"
fi

echo ""

# Step 4: Prepare docs directory
echo "📁 Step 4: Preparing docs/ directory..."

# Clean existing docs directory
if [ -d "docs/" ]; then
    echo "🧹 Cleaning existing docs/ directory..."
    rm -rf docs/
fi

# Create fresh docs directory
mkdir -p docs/

# Step 5: Copy publication.crate contents to docs/
echo "📦 Step 5: Copying publication crate to docs/..."
cp -r publication.crate/* docs/

echo "✅ Publication crate copied to docs/"
echo ""

# Step 6: Create enhanced landing page
echo "🎨 Step 6: Creating enhanced landing page..."

# Create a comprehensive index.html that showcases the shoreline publication
cat > docs/index.html << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>CoastSat Shoreline Publication - $SITE_ID</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
            background: #f8f9fa;
            color: #333;
        }
        
        .header {
            text-align: center;
            background: linear-gradient(135deg, #4299e1 0%, #38b2ac 100%);
            color: white;
            padding: 40px 20px;
            border-radius: 10px;
            margin-bottom: 30px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        }
        
        .header h1 {
            margin: 0 0 10px 0;
            font-size: 2.5rem;
        }
        
        .header p {
            margin: 0;
            font-size: 1.1rem;
            opacity: 0.9;
        }
        
        .cards {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        
        .card {
            background: white;
            border-radius: 8px;
            padding: 25px;
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
            transition: transform 0.2s ease, box-shadow 0.2s ease;
        }
        
        .card:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 8px rgba(0, 0, 0, 0.15);
        }
        
        .card h2 {
            margin: 0 0 15px 0;
            color: #4299e1;
            font-size: 1.4rem;
        }
        
        .card p {
            margin: 0 0 20px 0;
            line-height: 1.6;
            color: #666;
        }
        
        .btn {
            display: inline-block;
            padding: 12px 24px;
            background: #4299e1;
            color: white;
            text-decoration: none;
            border-radius: 5px;
            font-weight: 500;
            transition: background-color 0.2s ease;
        }
        
        .btn:hover {
            background: #3182ce;
        }
        
        .btn.secondary {
            background: #718096;
        }
        
        .btn.secondary:hover {
            background: #4a5568;
        }
        
        .meta {
            background: white;
            border-radius: 8px;
            padding: 20px;
            margin-top: 20px;
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
        }
        
        .meta h3 {
            margin: 0 0 15px 0;
            color: #333;
        }
        
        .meta-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
        }
        
        .meta-item {
            display: flex;
            flex-direction: column;
        }
        
        .meta-label {
            font-size: 0.9rem;
            font-weight: 600;
            color: #666;
            margin-bottom: 5px;
        }
        
        .meta-value {
            font-size: 1rem;
            color: #333;
        }
        
        .footer {
            text-align: center;
            margin-top: 40px;
            padding: 20px;
            color: #666;
            font-size: 0.9rem;
        }
        
        @media (max-width: 768px) {
            .cards {
                grid-template-columns: 1fr;
            }
            
            .header h1 {
                font-size: 2rem;
            }
            
            .meta-grid {
                grid-template-columns: 1fr;
            }
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>🏖️ CoastSat Shoreline Publication</h1>
        <p>LivePublication for Site $SITE_ID</p>
    </div>
    
    <div class="cards">
        <div class="card">
            <h2>Shoreline Publication Report</h2>
            <p>
                View the interactive shoreline analysis report for this site, based on the current state of the 
                <a href="https://github.com/UoA-eResearch/CoastSat" target="_blank" style="color: #4299e1; text-decoration: none;">CoastSat experiment</a>. 
                This publication dynamically reflects the latest shoreline change analysis and computational workflows.
            </p>
            <a href="shorelinepublication.html" class="btn">View Publication</a>
        </div>
        
        <div class="card">
            <h2>Publication Crate</h2>
            <p>
                Explore the Publication Crate research object containerising the shoreline publication, 
                its generation tools and scripts, and the interface.crate model representing the CoastSat shoreline experiment.
            </p>
            <a href="ro-crate-preview.html" class="btn secondary">Browse RO-Crate</a>
        </div>
        
        <div class="card">
            <h2>Version Comparison</h2>
            <p>
                View two versions of the shoreline publication dependent on different states of the CoastSat experiment.
            </p>
            <a href="version-comparison.html" class="btn secondary">View Comparison</a>
        </div>
    </div>
    
    <div class="meta">
        <h3>Publication Metadata</h3>
        <div class="meta-grid">
            <div class="meta-item">
                <div class="meta-label">Site ID</div>
                <div class="meta-value">$SITE_ID</div>
            </div>
            <div class="meta-item">
                <div class="meta-label">Interface.crate Version</div>
                <div class="meta-value">$INTERFACE_CRATE_VERSION</div>
            </div>
            <div class="meta-item">
                <div class="meta-label">Generated</div>
                <div class="meta-value">$(date '+%B %d, %Y at %I:%M %p')</div>
            </div>
            <div class="meta-item">
                <div class="meta-label">Data Format</div>
                <div class="meta-value">RO-Crate + Stencila DNF</div>
            </div>
        </div>
    </div>
    
    <div class="footer">
        <p>
            Generated by the CoastSat <strong>Shoreline LivePublication</strong> System.
        </p>
    </div>
</body>
</html>
EOF

# Ensure we also have the ro-crate-preview.html available
if [ ! -f "docs/ro-crate-preview.html" ] && [ -f "publication.crate/ro-crate-preview.html" ]; then
    cp publication.crate/ro-crate-preview.html docs/
fi

echo "✅ Enhanced landing page created"
echo ""

# Step 6.5: Generate version comparison page with actual shoreline publications
echo "🔄 Step 6.5: Generating version comparison with real shoreline publications..."

echo "Generating comparison between $COMPARISON_VERSION_1 and $COMPARISON_VERSION_2..."

# Check if we have the enhanced test script available
if [ ! -f "./tests/test_publication_enhanced.sh" ]; then
    echo "⚠️  Enhanced test script not found, skipping version comparison generation"
    echo "✅ Version comparison placeholder created"
else
    # Create backup of current publication.crate if it exists
    if [ -d "publication.crate" ]; then
        mv publication.crate publication.crate.backup
    fi

    echo "Building first version ($COMPARISON_VERSION_1)..."
    # Build first version for comparison
    if ./tests/test_publication_enhanced.sh "$SITE_ID" --no-open --populate-crate --interface-crate "$COMPARISON_VERSION_1" > /dev/null 2>&1; then
        # Generate first shoreline publication directly to docs
        if [ -f "shorelinepublication.html" ]; then
            cp shorelinepublication.html docs/shorelinepublication-v1.html
            echo "Generated version 1 shoreline publication"
        fi
    else
        echo "⚠️  Failed to generate version 1, using current publication as fallback"
        if [ -f "docs/shorelinepublication.html" ]; then
            cp docs/shorelinepublication.html docs/shorelinepublication-v1.html
        fi
    fi

    echo "Building second version ($COMPARISON_VERSION_2)..."
    # Clean for second version
    if [ -d "publication.crate" ]; then
        rm -rf publication.crate
    fi

    # Build second version for comparison
    if ./tests/test_publication_enhanced.sh "$SITE_ID" --no-open --populate-crate --interface-crate "$COMPARISON_VERSION_2" > /dev/null 2>&1; then
        # Generate second shoreline publication directly to docs
        if [ -f "shorelinepublication.html" ]; then
            cp shorelinepublication.html docs/shorelinepublication-v2.html
            echo "Generated version 2 shoreline publication"
        fi
    else
        echo "⚠️  Failed to generate version 2, using current publication as fallback"
        if [ -f "docs/shorelinepublication.html" ]; then
            cp docs/shorelinepublication.html docs/shorelinepublication-v2.html
        fi
    fi

    # Restore original publication.crate if we had a backup
    if [ -d "publication.crate.backup" ]; then
        rm -rf publication.crate
        mv publication.crate.backup publication.crate
    fi
fi

# Create a comparison page that shows differences between interface.crate versions
cat > docs/version-comparison.html << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Version Comparison - CoastSat Shoreline Publication</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            margin: 0;
            padding: 20px;
            background: #f8f9fa;
            color: #333;
        }
        
        .header {
            text-align: center;
            background: linear-gradient(135deg, #4299e1 0%, #38b2ac 100%);
            color: white;
            padding: 30px 20px;
            border-radius: 10px;
            margin-bottom: 20px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        }
        
        .header h1 {
            margin: 0 0 10px 0;
            font-size: 2rem;
        }
        
        .header p {
            margin: 0;
            font-size: 1rem;
            opacity: 0.9;
        }
        
        .comparison-container {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 20px;
            margin-bottom: 20px;
        }
        
        .version-panel {
            background: white;
            border-radius: 8px;
            padding: 20px;
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
        }
        
        .version-panel h3 {
            margin: 0 0 15px 0;
            color: #4299e1;
            border-bottom: 2px solid #e2e8f0;
            padding-bottom: 10px;
        }
        
        .version-frame {
            width: 100%;
            height: 600px;
            border: 1px solid #e2e8f0;
            border-radius: 5px;
        }
        
        .info-section {
            background: white;
            border-radius: 8px;
            padding: 20px;
            margin-bottom: 20px;
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
        }
        
        .info-section h3 {
            margin: 0 0 15px 0;
            color: #333;
        }
        
        .nav-buttons {
            text-align: center;
            margin: 20px 0;
        }
        
        .btn {
            display: inline-block;
            padding: 12px 24px;
            background: #4299e1;
            color: white;
            text-decoration: none;
            border-radius: 5px;
            font-weight: 500;
            margin: 0 10px;
            transition: background-color 0.2s ease;
        }
        
        .btn:hover {
            background: #3182ce;
        }
        
        .btn.secondary {
            background: #718096;
        }
        
        .btn.secondary:hover {
            background: #4a5568;
        }
        
        @media (max-width: 768px) {
            .comparison-container {
                grid-template-columns: 1fr;
            }
            
            .nav-buttons .btn {
                display: block;
                margin: 10px auto;
                max-width: 200px;
            }
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>🏖️ Version Comparison</h1>
        <p>Exploring how shoreline publications evolve with different interface.crate versions</p>
    </div>
    
    <div class="info-section">
        <h3>Understanding Version Evolution</h3>
        <p>
            This comparison demonstrates how shoreline publications adapt to the state of the computational research over time. 
            Each interface.crate version represents a state of the CoastSat experiment, with its specific computational 
            workflow and results, resulting in different shoreline analysis outputs and visualizations.
        </p>
    </div>
    
    <div class="comparison-container">
        <div class="version-panel">
            <h3>Version: $COMPARISON_VERSION_1</h3>
            <iframe src="shorelinepublication-v1.html" class="version-frame" title="Version 1 Shoreline Publication"></iframe>
        </div>
        
        <div class="version-panel">
            <h3>Version: $COMPARISON_VERSION_2</h3>
            <iframe src="shorelinepublication-v2.html" class="version-frame" title="Version 2 Shoreline Publication"></iframe>
        </div>
    </div>
    
    <div class="info-section">
        <h3>Generate Your Own Comparison</h3>
        <p>
            You can create live comparisons between any two interface.crate versions using the built-in comparison tools. 
            This allows you to explore how different states of the CoastSat experiment affect the resulting shoreline publications.
        </p>
        
        <h4>Using the Enhanced Test Script</h4>
        <p>
            The easiest way to generate comparisons is using the enhanced test script:
        </p>
        <pre style="background: #2d3748; color: #e2e8f0; padding: 15px; border-radius: 5px; overflow-x: auto;">
# Run enhanced test with specific interface.crate version
./tests/test_publication_enhanced.sh SITE_ID --interface-crate VERSION

# Example comparisons:
./tests/test_publication_enhanced.sh nzd0001 --interface-crate latest
./tests/test_publication_enhanced.sh nzd0001 --interface-crate interface.crate-d61c2052a-20250725024714

# Generate populated crates for comparison
./tests/test_publication_enhanced.sh nzd0001 --populate-crate --interface-crate latest
        </pre>
        
        <h4>Manual Version Generation</h4>
        <p>
            For more control, you can manually generate specific versions using the shoreline publication system:
        </p>
        <pre style="background: #2d3748; color: #e2e8f0; padding: 15px; border-radius: 5px; overflow-x: auto;">
# Generate different versions for comparison
./tests/test_publication_enhanced.sh SITE_ID --interface-crate VERSION1 --output shoreline-v1.html
./tests/test_publication_enhanced.sh SITE_ID --interface-crate VERSION2 --output shoreline-v2.html

# Available interface.crate versions can be found in the CoastSat-interface.crate releases
        </pre>
    </div>
    
    <div class="nav-buttons">
        <a href="index.html" class="btn secondary">← Back to Home</a>
        <a href="shorelinepublication.html" class="btn">View Current Publication</a>
        <a href="ro-crate-preview.html" class="btn secondary">Browse Metadata</a>
    </div>
    
    <div style="text-align: center; margin-top: 40px; padding: 20px; color: #666; font-size: 0.9rem;">
        <p>Generated by the CoastSat <strong>Shoreline LivePublication</strong> System.</p>
    </div>
</body>
</html>
EOF

echo "✅ Version comparison page created"
echo ""

# Step 7: Set up GitHub Pages fallback
echo "🔄 Step 7: Setting up GitHub Pages fallbacks..."

# Ensure we have the publication HTML file in docs/
if [ ! -f "docs/shorelinepublication.html" ] && [ -f "shorelinepublication.html" ]; then
    cp shorelinepublication.html docs/
    echo "✅ Copied shorelinepublication.html to docs/"
fi

# Create alternative index fallback if needed
if [ ! -f "docs/ro-crate-preview.html" ]; then
    echo "⚠️  ro-crate-preview.html not found, checking for alternatives..."
    
    if [ -f "docs/shorelinepublication.html" ]; then
        # Create a simple redirect index if no ro-crate-preview exists
        cat > docs/ro-crate-preview.html << EOF
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Shoreline Publication - $SITE_ID</title>
    <meta http-equiv="refresh" content="0; url=shorelinepublication.html">
</head>
<body>
    <p>If you are not redirected automatically, <a href="shorelinepublication.html">click here</a>.</p>
</body>
</html>
EOF
        echo "✅ Created fallback ro-crate-preview.html"
    fi
fi

echo ""

# Step 8: Clean up publication.crate directory (with user prompt)
echo "🧹 Step 8: Cleaning up publication.crate directory..."
read -p "Remove publication.crate/ directory? [y/N]: " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [ -d "publication.crate/" ]; then
        rm -rf publication.crate/
        echo "✅ Removed publication.crate/ directory"
    else
        echo "ℹ️  publication.crate/ directory not found"
    fi
else
    echo "✅ Keeping publication.crate/ directory"
fi

echo ""

# Step 9: Summary and next steps
echo "🎉 GitHub Pages publication ready!"
echo ""
echo "📋 Summary:"
echo "   🌐 Landing Page: docs/index.html"
echo "   📄 Shoreline Publication: docs/shorelinepublication.html"
echo "   📦 RO-Crate Preview: docs/ro-crate-preview.html"
echo "   � Version Comparison: docs/version-comparison.html"
echo "   �📊 Metadata: docs/ro-crate-metadata.json"
echo "   📁 Site ID: $SITE_ID"
echo "   🔢 Interface.crate: $INTERFACE_CRATE_VERSION"
echo ""
echo "🚀 Next steps to publish:"
echo "   1. git add docs/"
echo "   2. git commit -m \"Publish $SITE_ID shoreline publication to GitHub Pages\""
echo "   3. git push"
echo "   4. Enable GitHub Pages in repository settings (source: docs/ folder)"
echo ""
echo "🌐 After enabling GitHub Pages, your publication will be available at:"
echo "   https://GusEllerm.github.io/CoastSat-shorelinepublication/"
echo ""
echo "The landing page provides links to:"
echo "   • Interactive shoreline publication (primary research output)"
echo "   • RO-Crate browser (metadata and provenance explorer)"
echo "   • Version comparison (side-by-side interface.crate comparison)"
echo ""
echo "✨ Done!"
