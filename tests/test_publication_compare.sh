#!/bin/bash

set -e  # Exit on any error

# Parse arguments
AUTO_OPEN=true
SITE_ID=""
VERSION_1=""
VERSION_2=""
OUTPUT_DIR="comparison_output"

show_help() {
    echo "Usage: $0 <SITE_ID> <VERSION_1> <VERSION_2> [--no-open] [--output-dir DIR] [--help]"
    echo ""
    echo "Compare publications generated with different interface.crate versions"
    echo ""
    echo "Arguments:"
    echo "  SITE_ID         Site ID to generate publications for (e.g., aus0001, nzd0001)"
    echo "  VERSION_1       First interface.crate version (e.g., latest, interface.crate-cb67e8e26-20250801011405)"
    echo "  VERSION_2       Second interface.crate version for comparison"
    echo ""
    echo "Options:"
    echo "  --no-open       Don't automatically open the comparison HTML"
    echo "  --output-dir    Directory to store comparison outputs (default: comparison_output)"
    echo "  --help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 aus0001 latest interface.crate-d61c2052a-20250725024714"
    echo "  $0 nzd0001 interface.crate-cb67e8e26-20250801011405 interface.crate-d61c2052a-20250725024714 --no-open"
    echo ""
    echo "Available versions can be found with:"
    echo "  curl -s \"https://api.github.com/repos/GusEllerm/CoastSat-interface.crate/releases\" | grep '\"tag_name\"' | head -10"
}

while [[ $# -gt 0 ]]; do
    case $1 in
        --no-open)
            AUTO_OPEN=false
            shift
            ;;
        --output-dir)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            if [ -z "$SITE_ID" ]; then
                SITE_ID="$1"
            elif [ -z "$VERSION_1" ]; then
                VERSION_1="$1"
            elif [ -z "$VERSION_2" ]; then
                VERSION_2="$1"
            else
                echo "❌ Too many arguments provided"
                show_help
                exit 1
            fi
            shift
            ;;
    esac
done

# Validate required arguments
if [ -z "$SITE_ID" ] || [ -z "$VERSION_1" ] || [ -z "$VERSION_2" ]; then
    echo "❌ Missing required arguments"
    show_help
    exit 1
fi

if [ "$VERSION_1" = "$VERSION_2" ]; then
    echo "❌ Cannot compare the same version with itself"
    echo "Please provide two different interface.crate versions"
    exit 1
fi

echo "🔍 CoastSat Publication Comparison Tool"
echo "========================================"
echo "📍 Site ID: $SITE_ID"
echo "🔢 Version 1: $VERSION_1"
echo "🔢 Version 2: $VERSION_2"
echo "📂 Output Directory: $OUTPUT_DIR"
echo ""

# Create output directory structure
mkdir -p "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR/version1"
mkdir -p "$OUTPUT_DIR/version2"

# Function to generate publication with specific version
generate_publication() {
    local version=$1
    local output_subdir=$2
    local version_label=$3
    
    echo "🚀 Generating publication with $version_label ($version)..."
    
    # Clean up any existing publication.crate
    if [ -d "publication.crate" ]; then
        rm -rf publication.crate/
    fi
    
    # Generate publication with specified version
    if [ "$version" = "latest" ]; then
        timeout 300 python src/crate_builder.py || {
            echo "❌ Failed to build crate with $version_label"
            return 1
        }
    else
        timeout 300 python src/crate_builder.py --interface-crate "$version" || {
            echo "❌ Failed to build crate with $version_label"
            return 1
        }
    fi
    
    # Generate HTML publication
    python src/publication_logic.py "$SITE_ID" || {
        echo "❌ Failed to generate publication with $version_label"
        return 1
    }
    
    # Copy results to output directory
    if [ -f "shorelinepublication.html" ]; then
        cp "shorelinepublication.html" "$OUTPUT_DIR/$output_subdir/publication.html"
        echo "✅ $version_label publication saved to $OUTPUT_DIR/$output_subdir/publication.html"
        
        # Get file size for comparison
        local file_size=$(ls -lh "shorelinepublication.html" | awk '{print $5}')
        echo "📊 File size: $file_size"
    else
        echo "❌ HTML publication not generated for $version_label"
        return 1
    fi
}

# Generate publications
echo "🔧 Starting publication generation..."
echo ""

generate_publication "$VERSION_1" "version1" "Version 1"
echo ""
generate_publication "$VERSION_2" "version2" "Version 2"
echo ""

# Create comparison HTML page
echo "🎨 Creating comparison interface..."

cat > "$OUTPUT_DIR/comparison.html" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Publication Comparison</title>
    <style>
        body {
            margin: 0;
            padding: 0;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: #f5f5f5;
        }
        
        .header {
            background: #2c3e50;
            color: white;
            padding: 15px;
            text-align: center;
            position: fixed;
            top: 0;
            left: 0;
            right: 0;
            z-index: 1000;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        
        .header h1 {
            margin: 0;
            font-size: 20px;
        }
        
        .version-info {
            font-size: 14px;
            margin-top: 5px;
            opacity: 0.9;
        }
        
        .container {
            display: flex;
            height: 100vh;
            padding-top: 80px;
        }
        
        .panel {
            flex: 1;
            display: flex;
            flex-direction: column;
            border-right: 2px solid #34495e;
        }
        
        .panel:last-child {
            border-right: none;
        }
        
        .panel-header {
            background: #34495e;
            color: white;
            padding: 10px;
            text-align: center;
            font-weight: bold;
            font-size: 14px;
        }
        
        .iframe-container {
            flex: 1;
            position: relative;
        }
        
        iframe {
            width: 100%;
            height: 100%;
            border: none;
            background: white;
        }
        
        .controls {
            position: fixed;
            bottom: 20px;
            right: 20px;
            z-index: 1001;
        }
        
        .btn {
            background: #3498db;
            color: white;
            border: none;
            padding: 10px 15px;
            margin: 0 5px;
            border-radius: 5px;
            cursor: pointer;
            font-size: 12px;
        }
        
        .btn:hover {
            background: #2980b9;
        }
        
        .sync-indicator {
            position: fixed;
            top: 85px;
            right: 20px;
            background: #27ae60;
            color: white;
            padding: 5px 10px;
            border-radius: 3px;
            font-size: 12px;
            z-index: 1001;
        }
        
        .sync-indicator.disabled {
            background: #95a5a6;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>📊 Publication Comparison</h1>
        <div class="version-info">
            <strong>Site:</strong> SITE_ID_PLACEHOLDER | 
            <strong>Left:</strong> VERSION_1_PLACEHOLDER | 
            <strong>Right:</strong> VERSION_2_PLACEHOLDER
        </div>
    </div>
    
    <div class="sync-indicator" id="syncIndicator">🔄 Synchronized Scrolling</div>
    
    <div class="container">
        <div class="panel">
            <div class="panel-header">VERSION_1_PLACEHOLDER</div>
            <div class="iframe-container">
                <iframe id="iframe1" src="version1/publication.html"></iframe>
            </div>
        </div>
        
        <div class="panel">
            <div class="panel-header">VERSION_2_PLACEHOLDER</div>
            <div class="iframe-container">
                <iframe id="iframe2" src="version2/publication.html"></iframe>
            </div>
        </div>
    </div>
    
    <div class="controls">
        <button class="btn" onclick="toggleSync()">Toggle Sync</button>
        <button class="btn" onclick="resetView()">Reset View</button>
        <button class="btn" onclick="openOriginals()">Open Originals</button>
    </div>
    
    <script>
        let syncEnabled = true;
        let isScrolling = false;
        
        const iframe1 = document.getElementById('iframe1');
        const iframe2 = document.getElementById('iframe2');
        const syncIndicator = document.getElementById('syncIndicator');
        
        function setupSyncScrolling() {
            iframe1.onload = function() {
                const doc1 = iframe1.contentDocument || iframe1.contentWindow.document;
                doc1.addEventListener('scroll', function() {
                    if (syncEnabled && !isScrolling) {
                        isScrolling = true;
                        const doc2 = iframe2.contentDocument || iframe2.contentWindow.document;
                        const scrollPercentage = doc1.documentElement.scrollTop / (doc1.documentElement.scrollHeight - doc1.documentElement.clientHeight);
                        doc2.documentElement.scrollTop = scrollPercentage * (doc2.documentElement.scrollHeight - doc2.documentElement.clientHeight);
                        setTimeout(() => { isScrolling = false; }, 50);
                    }
                });
            };
            
            iframe2.onload = function() {
                const doc2 = iframe2.contentDocument || iframe2.contentWindow.document;
                doc2.addEventListener('scroll', function() {
                    if (syncEnabled && !isScrolling) {
                        isScrolling = true;
                        const doc1 = iframe1.contentDocument || iframe1.contentWindow.document;
                        const scrollPercentage = doc2.documentElement.scrollTop / (doc2.documentElement.scrollHeight - doc2.documentElement.clientHeight);
                        doc1.documentElement.scrollTop = scrollPercentage * (doc1.documentElement.scrollHeight - doc1.documentElement.clientHeight);
                        setTimeout(() => { isScrolling = false; }, 50);
                    }
                });
            };
        }
        
        function toggleSync() {
            syncEnabled = !syncEnabled;
            syncIndicator.textContent = syncEnabled ? '🔄 Synchronized Scrolling' : '⏸️ Sync Disabled';
            syncIndicator.className = syncEnabled ? 'sync-indicator' : 'sync-indicator disabled';
        }
        
        function resetView() {
            try {
                const doc1 = iframe1.contentDocument || iframe1.contentWindow.document;
                const doc2 = iframe2.contentDocument || iframe2.contentWindow.document;
                doc1.documentElement.scrollTop = 0;
                doc2.documentElement.scrollTop = 0;
            } catch (e) {
                console.log('Cannot access iframe content');
            }
        }
        
        function openOriginals() {
            window.open('version1/publication.html', '_blank');
            window.open('version2/publication.html', '_blank');
        }
        
        setupSyncScrolling();
    </script>
</body>
</html>
EOF

# Replace placeholders in the HTML
sed -i '' "s/SITE_ID_PLACEHOLDER/$SITE_ID/g" "$OUTPUT_DIR/comparison.html"
sed -i '' "s/VERSION_1_PLACEHOLDER/$VERSION_1/g" "$OUTPUT_DIR/comparison.html"
sed -i '' "s/VERSION_2_PLACEHOLDER/$VERSION_2/g" "$OUTPUT_DIR/comparison.html"

echo "✅ Comparison interface created: $OUTPUT_DIR/comparison.html"

# Generate summary report
echo "📋 Generating comparison report..."

cat > "$OUTPUT_DIR/comparison_report.txt" << EOF
CoastSat Publication Comparison Report
=====================================

Generated: $(date)
Site ID: $SITE_ID

Version 1: $VERSION_1
Version 2: $VERSION_2

File Sizes:
-----------
Version 1: $(ls -lh "$OUTPUT_DIR/version1/publication.html" | awk '{print $5}')
Version 2: $(ls -lh "$OUTPUT_DIR/version2/publication.html" | awk '{print $5}')

Files Generated:
---------------
- $OUTPUT_DIR/comparison.html         (Side-by-side comparison interface)
- $OUTPUT_DIR/version1/publication.html  (Publication with $VERSION_1)
- $OUTPUT_DIR/version2/publication.html  (Publication with $VERSION_2)
- $OUTPUT_DIR/comparison_report.txt   (This report)

Usage:
------
Open $OUTPUT_DIR/comparison.html in a web browser to view the side-by-side comparison.
The interface includes synchronized scrolling and controls to toggle sync, reset view, and open original files.

EOF

echo "✅ Comparison report saved: $OUTPUT_DIR/comparison_report.txt"

# Final cleanup
if [ -d "publication.crate" ]; then
    rm -rf publication.crate/
fi

if [ -f "shorelinepublication.html" ]; then
    rm "shorelinepublication.html"
fi

echo ""
echo "🎉 Comparison generation completed successfully!"
echo ""
echo "📊 Summary:"
echo "   📁 Output directory: $OUTPUT_DIR"
echo "   🌐 Comparison interface: $OUTPUT_DIR/comparison.html"
echo "   📋 Report: $OUTPUT_DIR/comparison_report.txt"
echo ""
echo "🔍 File sizes:"
echo "   Version 1 ($VERSION_1): $(ls -lh "$OUTPUT_DIR/version1/publication.html" | awk '{print $5}')"
echo "   Version 2 ($VERSION_2): $(ls -lh "$OUTPUT_DIR/version2/publication.html" | awk '{print $5}')"
echo ""

if [ "$AUTO_OPEN" = true ]; then
    echo "🚀 Opening comparison interface..."
    if command -v open >/dev/null 2>&1; then
        open "$OUTPUT_DIR/comparison.html"
        echo "✅ Opened in default browser"
    elif command -v xdg-open >/dev/null 2>&1; then
        xdg-open "$OUTPUT_DIR/comparison.html"
        echo "✅ Opened in default browser"
    elif command -v start >/dev/null 2>&1; then
        start "$OUTPUT_DIR/comparison.html"
        echo "✅ Opened in default browser"
    else
        echo "⚠️  Could not auto-open. Please open manually:"
        echo "   file://$(pwd)/$OUTPUT_DIR/comparison.html"
    fi
else
    echo "ℹ️  Auto-open disabled. To view the comparison:"
    echo "   file://$(pwd)/$OUTPUT_DIR/comparison.html"
fi

echo ""
echo "🎯 Next steps:"
echo "   • Scroll through both publications to compare differences"
echo "   • Use the toggle sync button to enable/disable synchronized scrolling"
echo "   • Click 'Open Originals' to view publications in separate tabs"
echo "   • Check the comparison report for file size differences"
