#!/bin/bash

# Shoreline Publication Comparison Tool - Interactive Version
# This script generates two shoreline publications with different interface.crate versions
# and creates a side-by-side comparison interface for easy analysis

# Set strict error handling
set -euo pipefail

# Configuration
DEFAULT_SITE_ID="nzd0001"
DEFAULT_OUTPUT_DIR="./comparison_output"
AUTO_OPEN=true

# Color codes for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Ensure we're in the right directory (project root)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

show_help() {
    cat << EOF
🏖️ Shoreline Publication Comparison Tool

USAGE:
    $0 [OPTIONS]

OPTIONS:
    --output-dir DIR    Specify output directory (default: ./comparison_output)
    --no-auto-open      Don't automatically open browser
    --help              Show this help message

EXAMPLES:
    $0                           # Interactive mode (recommended)
    $0 --output-dir ./my_comparison
    $0 --help

DESCRIPTION:
    This tool generates two shoreline publications using different interface.crate versions
    and creates a side-by-side comparison interface. The comparison includes:
    
    • Visual diff highlighting changes between versions
    • Synchronized scrolling between both versions
    • File size comparison
    • Interactive controls for detailed analysis
    
    In interactive mode, you'll be prompted to:
    1. Select a site ID from available options
    2. Choose from the latest interface.crate versions available on GitHub
    3. Specify which two versions to compare
    
    The script automatically fetches available versions from the GitHub repository.

EOF
}

fetch_available_versions() {
    echo -e "${BLUE}📡 Fetching available interface.crate versions from GitHub...${NC}" >&2
    
    # First try to fetch from the interface.crate repository
    local releases_json
    if releases_json=$(curl -s "https://api.github.com/repos/GusEllerm/CoastSat-interface.crate/releases?per_page=15" 2>/dev/null); then
        local versions
        if versions=$(echo "$releases_json" | grep -o '"tag_name": *"[^"]*"' | sed 's/"tag_name": *"\([^"]*\)"/\1/' | head -10 2>/dev/null); then
            if [ -n "$versions" ]; then
                echo "$versions"
                return
            fi
        fi
    fi
    
    echo -e "${YELLOW}⚠️  Could not fetch from interface.crate repository, trying main CoastSat repository...${NC}" >&2
    
    # Fallback to main CoastSat repository
    if releases_json=$(curl -s "https://api.github.com/repos/kvos/CoastSat/releases?per_page=15" 2>/dev/null); then
        local versions
        if versions=$(echo "$releases_json" | grep -o '"tag_name": *"[^"]*"' | sed 's/"tag_name": *"\([^"]*\)"/\1/' | head -10 2>/dev/null); then
            if [ -n "$versions" ]; then
                echo "$versions"
                return
            fi
        fi
    fi
    
    echo -e "${RED}❌ Failed to fetch releases from GitHub API${NC}" >&2
    echo -e "${YELLOW}💡 Please check your internet connection or try again later${NC}" >&2
    echo "" >&2
    echo "As a fallback, you can manually specify versions from the following examples:" >&2
    echo "  • latest" >&2
    echo "  • interface.crate-cb67e8e26-20250801011405" >&2
    echo "  • interface.crate-d61c2052a-20250725024714" >&2
    echo "" >&2
    exit 1
}

prompt_for_site() {
    echo "" >&2
    echo -e "${CYAN}🏖️ Available site options:${NC}" >&2
    echo "   • Format: SITE-ID (e.g., nzd0001, aus0001)" >&2
    echo "   • Australian coast: aus0001 to aus0089" >&2
    echo "   • New Zealand coast: nzd0001 to nzd0999" >&2
    echo "   • Custom site ID" >&2
    echo "" >&2
    echo "Popular test sites:" >&2
    echo "   • nzd0001 -- active shoreline change, NZ site" >&2
    echo "   • nzd0361 -- stable shoreline, NZ site" >&2
    echo "   • nzd0314 -- variable shoreline data" >&2
    echo "   • aus0001 -- Australian east coast site" >&2
    echo "" >&2
    
    while true; do
        printf "${GREEN}Enter site ID (default: $DEFAULT_SITE_ID): ${NC}" >&2
        read -r input
        
        if [ -z "$input" ]; then
            echo "$DEFAULT_SITE_ID"
            return
        fi
        
        if [[ "$input" =~ ^[a-zA-Z0-9_-]+$ ]]; then
            echo "$input"
            return
        else
            echo -e "${RED}❌ Invalid site ID format. Please use the format SITE-ID (e.g., nzd0001, aus0001).${NC}" >&2
        fi
    done
}

prompt_for_version() {
    local prompt_text="$1"
    local versions="$2"
    local exclude_version="$3"
    
    echo "" >&2
    echo -e "${CYAN}$prompt_text${NC}" >&2
    echo "Available versions:" >&2
    
    local i=1
    local version_array=()
    
    while IFS= read -r version; do
        if [ "$version" != "$exclude_version" ]; then
            echo "   $i) $version" >&2
            version_array+=("$version")
            ((i++))
        fi
    done <<< "$versions"
    
    echo "" >&2
    
    while true; do
        printf "${GREEN}Select version number (1-${#version_array[@]}): ${NC}" >&2
        read -r choice
        
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#version_array[@]}" ]; then
            echo "${version_array[$((choice-1))]}"
            return
        else
            echo -e "${RED}❌ Invalid selection. Please enter a number between 1 and ${#version_array[@]}.${NC}" >&2
        fi
    done
}

generate_shoreline_publication() {
    local version=$1
    local output_subdir=$2
    
    echo -e "${BLUE}� Generating shoreline publication for version: $version${NC}"
    
    # Clean up any existing publication.crate
    if [ -d "publication.crate" ]; then
        rm -rf publication.crate/
        echo "   🧹 Cleaned existing publication.crate"
    fi
    
    echo "   📥 Building interface.crate version: $version"
    
    # Generate publication with specified version using the enhanced test script
    if [ "$version" = "latest" ]; then
        if timeout 300 ./tests/test_publication_enhanced.sh "$SITE_ID" --no-open --populate-crate --interface-crate latest > /dev/null 2>&1; then
            echo -e "${GREEN}   ✅ Successfully built publication with latest interface.crate${NC}"
        else
            echo -e "${RED}   ❌ Failed to build publication with latest interface.crate${NC}"
            return 1
        fi
    else
        if timeout 300 ./tests/test_publication_enhanced.sh "$SITE_ID" --no-open --populate-crate --interface-crate "$version" > /dev/null 2>&1; then
            echo -e "${GREEN}   ✅ Successfully built publication with interface.crate $version${NC}"
        else
            echo -e "${RED}   ❌ Failed to build publication with interface.crate $version${NC}"
            return 1
        fi
    fi
    
    # Copy results to output directory
    if [ -f "shorelinepublication.html" ]; then
        cp "shorelinepublication.html" "$OUTPUT_DIR/$output_subdir/publication.html"
        echo "   📄 Shoreline publication saved to $OUTPUT_DIR/$output_subdir/publication.html"
        
        # Get file size for comparison
        local file_size=$(ls -lh "shorelinepublication.html" | awk '{print $5}')
        echo "   📊 File size: $file_size"
        
        # Also copy any additional metadata if available
        if [ -f "publication.crate/ro-crate-metadata.json" ]; then
            cp "publication.crate/ro-crate-metadata.json" "$OUTPUT_DIR/$output_subdir/"
            echo "   📋 Metadata copied"
        fi
        
        return 0
    else
        echo -e "${RED}   ❌ HTML publication not generated${NC}"
        return 1
    fi
}

# Parse command line arguments
OUTPUT_DIR="$DEFAULT_OUTPUT_DIR"

while [[ $# -gt 0 ]]; do
    case $1 in
        --output-dir)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --no-auto-open)
            AUTO_OPEN=false
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Unknown option: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

# Interactive mode - prompt for inputs
echo -e "${CYAN}🏖️ Welcome to the Shoreline Publication Comparison Tool${NC}"
echo "=========================================================="
echo ""

# Check if we have the required test script
if [ ! -f "./tests/test_publication_enhanced.sh" ]; then
    echo -e "${RED}❌ Enhanced test script not found at ./tests/test_publication_enhanced.sh${NC}"
    echo -e "${YELLOW}💡 Please make sure you're running this script from the project root directory${NC}"
    exit 1
fi

# Fetch available versions
echo -e "${BLUE}🔍 Checking for available interface.crate versions...${NC}"
AVAILABLE_VERSIONS=$(fetch_available_versions)

# Interactive prompts
SITE_ID=$(prompt_for_site)
VERSION_1=$(prompt_for_version "📦 Select first interface.crate version:" "$AVAILABLE_VERSIONS" "")
VERSION_2=$(prompt_for_version "📦 Select second interface.crate version:" "$AVAILABLE_VERSIONS" "$VERSION_1")

# Validation
if [ "$VERSION_1" = "$VERSION_2" ]; then
    echo -e "${RED}❌ Cannot compare the same version with itself${NC}"
    echo "Please run the script again and select different versions"
    exit 1
fi

echo ""
echo -e "${CYAN}🔍 Comparison Configuration${NC}"
echo "==============================="
echo -e "${GREEN}📍 Site ID: $SITE_ID${NC}"
echo -e "${GREEN}🔢 Version 1: $VERSION_1${NC}"
echo -e "${GREEN}🔢 Version 2: $VERSION_2${NC}"
echo -e "${GREEN}📂 Output Directory: $OUTPUT_DIR${NC}"
echo ""

# Create output directory structure
echo -e "${BLUE}📁 Setting up output directories...${NC}"
mkdir -p "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR/version1"
mkdir -p "$OUTPUT_DIR/version2"

# Generate publications
echo -e "${BLUE}🔧 Starting publication generation...${NC}"
echo ""

echo -e "${YELLOW}📦 Generating Version 1 ($VERSION_1)...${NC}"
if ! generate_shoreline_publication "$VERSION_1" "version1"; then
    echo -e "${RED}❌ Failed to generate Version 1${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}📦 Generating Version 2 ($VERSION_2)...${NC}"
if ! generate_shoreline_publication "$VERSION_2" "version2"; then
    echo -e "${RED}❌ Failed to generate Version 2${NC}"
    exit 1
fi

echo ""

# Create comparison HTML page
echo -e "${BLUE}🎨 Creating comparison interface...${NC}"

# Create the comparison HTML interface
cat > "$OUTPUT_DIR/comparison.html" << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Shoreline Publication Comparison - $SITE_ID</title>
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
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        
        .header h1 {
            margin: 0;
            font-size: 18px;
            font-weight: 600;
        }
        
        .version-info {
            margin-top: 5px;
            font-size: 12px;
            opacity: 0.8;
        }
        
        .sync-indicator {
            position: fixed;
            top: 80px;
            right: 20px;
            background: #27ae60;
            color: white;
            padding: 8px 12px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: 500;
            z-index: 1001;
            transition: all 0.3s ease;
        }
        
        .sync-indicator.disabled {
            background: #e74c3c;
        }
        
        .container {
            display: flex;
            height: 100vh;
            padding-top: 110px;
            padding-bottom: 60px;
            gap: 2px;
        }
        
        .panel {
            flex: 1;
            display: flex;
            flex-direction: column;
            background: white;
            border-radius: 8px;
            margin: 10px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
            overflow: hidden;
        }
        
        .panel-header {
            background: #34495e;
            color: white;
            padding: 12px 20px;
            font-weight: 600;
            font-size: 14px;
            text-align: center;
        }
        
        .iframe-container {
            flex: 1;
            position: relative;
        }
        
        .iframe-container iframe {
            width: 100%;
            height: 100%;
            border: none;
            background: white;
        }
        
        .controls {
            position: fixed;
            bottom: 0;
            left: 0;
            right: 0;
            background: #ecf0f1;
            padding: 15px;
            text-align: center;
            border-top: 1px solid #bdc3c7;
            z-index: 1000;
        }
        
        .btn {
            background: #3498db;
            color: white;
            border: none;
            padding: 10px 20px;
            margin: 0 10px;
            border-radius: 5px;
            cursor: pointer;
            font-weight: 500;
            transition: background-color 0.3s ease;
        }
        
        .btn:hover {
            background: #2980b9;
        }
        
        .btn:active {
            transform: translateY(1px);
        }
        
        @media (max-width: 768px) {
            .container {
                flex-direction: column;
                padding-top: 120px;
            }
            
            .header h1 {
                font-size: 16px;
            }
            
            .version-info {
                font-size: 11px;
            }
            
            .btn {
                padding: 8px 15px;
                margin: 5px;
                font-size: 14px;
            }
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>🏖️ Shoreline Publication Comparison: $SITE_ID</h1>
        <div class="version-info">
            <strong>Left:</strong> $VERSION_1 | 
            <strong>Right:</strong> $VERSION_2
        </div>
    </div>
    
    <div class="sync-indicator" id="syncIndicator">🔄 Synchronized Scrolling</div>
    
    <div class="container">
        <div class="panel">
            <div class="panel-header">$VERSION_1</div>
            <div class="iframe-container">
                <iframe id="iframe1" src="version1/publication.html"></iframe>
            </div>
        </div>
        
        <div class="panel">
            <div class="panel-header">$VERSION_2</div>
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
        let doc1, doc2;
        
        const iframe1 = document.getElementById('iframe1');
        const iframe2 = document.getElementById('iframe2');
        const syncIndicator = document.getElementById('syncIndicator');
        
        function getIframeDocument(iframe) {
            try {
                return iframe.contentDocument || iframe.contentWindow.document;
            } catch (e) {
                console.log('Cannot access iframe content due to security restrictions');
                return null;
            }
        }
        
        function setupSyncScrolling() {
            // Wait for both iframes to load
            let iframe1Loaded = false;
            let iframe2Loaded = false;
            
            iframe1.onload = function() {
                iframe1Loaded = true;
                doc1 = getIframeDocument(iframe1);
                if (iframe1Loaded && iframe2Loaded) {
                    attachScrollListeners();
                }
            };
            
            iframe2.onload = function() {
                iframe2Loaded = true;
                doc2 = getIframeDocument(iframe2);
                if (iframe1Loaded && iframe2Loaded) {
                    attachScrollListeners();
                }
            };
        }
        
        function attachScrollListeners() {
            if (!doc1 || !doc2) {
                console.log('Cannot attach scroll listeners - iframe access restricted');
                // Hide sync indicator if we can't sync
                syncIndicator.style.display = 'none';
                return;
            }
            
            console.log('Setting up synchronized scrolling...');
            
            // Debounce function to smooth out rapid scroll events
            function debounce(func, wait) {
                let timeout;
                return function executedFunction(...args) {
                    const later = () => {
                        clearTimeout(timeout);
                        func(...args);
                    };
                    clearTimeout(timeout);
                    timeout = setTimeout(later, wait);
                };
            }
            
            // Smooth scroll sync function - same speed, not same position
            function syncScroll(sourceDoc, targetDoc) {
                if (!syncEnabled || isScrolling) return;
                
                isScrolling = true;
                
                try {
                    // Get source scroll position (absolute pixels)
                    const sourceScrollTop = sourceDoc.documentElement.scrollTop || sourceDoc.body.scrollTop || 0;
                    
                    // Get target document height info for bounds checking
                    const targetScrollHeight = targetDoc.documentElement.scrollHeight || targetDoc.body.scrollHeight || 1;
                    const targetClientHeight = targetDoc.documentElement.clientHeight || targetDoc.body.clientHeight || 1;
                    const maxTargetScroll = Math.max(0, targetScrollHeight - targetClientHeight);
                    
                    // Use the same absolute scroll position (same speed scrolling)
                    // But cap it at the maximum possible scroll for the target document
                    const targetScrollTop = Math.min(sourceScrollTop, maxTargetScroll);
                    
                    // Apply scroll directly with same pixel position
                    if (targetDoc.documentElement && typeof targetDoc.documentElement.scrollTop !== 'undefined') {
                        targetDoc.documentElement.scrollTop = targetScrollTop;
                    } else if (targetDoc.body) {
                        targetDoc.body.scrollTop = targetScrollTop;
                    }
                    
                    console.log(\`Same-speed sync: \${sourceScrollTop}px -> \${targetScrollTop}px (max: \${maxTargetScroll}px)\`);
                    
                } catch (e) {
                    console.log('Error syncing scroll:', e);
                }
                
                // Reset scrolling flag after a brief delay
                setTimeout(() => { 
                    isScrolling = false; 
                }, 50);
            }
            
            // Create debounced sync functions
            const syncToDoc2 = debounce(() => syncScroll(doc1, doc2), 16); // ~60fps
            const syncToDoc1 = debounce(() => syncScroll(doc2, doc1), 16);
            
            // Add scroll listeners with improved event handling
            const doc1ScrollHandler = function() {
                if (syncEnabled && !isScrolling) {
                    syncToDoc2();
                }
            };
            
            const doc2ScrollHandler = function() {
                if (syncEnabled && !isScrolling) {
                    syncToDoc1();
                }
            };
            
            doc1.addEventListener('scroll', doc1ScrollHandler, { passive: true });
            doc2.addEventListener('scroll', doc2ScrollHandler, { passive: true });
            
            console.log('Synchronized scrolling enabled with smooth debouncing');
        }
        
        function toggleSync() {
            syncEnabled = !syncEnabled;
            syncIndicator.textContent = syncEnabled ? '🔄 Synchronized Scrolling' : '⏸️ Sync Disabled';
            syncIndicator.className = syncEnabled ? 'sync-indicator' : 'sync-indicator disabled';
            console.log('Sync toggled:', syncEnabled);
        }
        
        function resetView() {
            console.log('Resetting view...');
            
            // Temporarily disable sync to avoid conflicts
            const wasEnabled = syncEnabled;
            syncEnabled = false;
            
            try {
                // Smooth scroll to top for both documents
                if (doc1) {
                    if (doc1.documentElement && typeof doc1.documentElement.scrollTop !== 'undefined') {
                        doc1.documentElement.scrollTo({ top: 0, behavior: 'smooth' });
                    } else if (doc1.body) {
                        doc1.body.scrollTo({ top: 0, behavior: 'smooth' });
                    }
                }
                
                if (doc2) {
                    if (doc2.documentElement && typeof doc2.documentElement.scrollTop !== 'undefined') {
                        doc2.documentElement.scrollTo({ top: 0, behavior: 'smooth' });
                    } else if (doc2.body) {
                        doc2.body.scrollTo({ top: 0, behavior: 'smooth' });
                    }
                }
                
                console.log('View reset successfully with smooth scrolling');
                
                // Re-enable sync after smooth scroll completes
                setTimeout(() => {
                    syncEnabled = wasEnabled;
                }, 1000);
                
            } catch (e) {
                console.log('Cannot reset view - iframe access restricted:', e);
                // Fallback: reload the iframes
                iframe1.src = iframe1.src;
                iframe2.src = iframe2.src;
                console.log('Reloaded iframes as fallback');
                
                // Re-enable sync immediately for fallback
                syncEnabled = wasEnabled;
            }
        }
        
        function openOriginals() {
            window.open('version1/publication.html', '_blank');
            window.open('version2/publication.html', '_blank');
        }
        
        // Initialize when page loads
        window.addEventListener('load', setupSyncScrolling);
        
        // Keyboard shortcuts
        document.addEventListener('keydown', function(e) {
            if (e.ctrlKey || e.metaKey) {
                switch(e.key) {
                    case 's':
                        e.preventDefault();
                        toggleSync();
                        break;
                    case 'r':
                        e.preventDefault();
                        resetView();
                        break;
                    case 'o':
                        e.preventDefault();
                        openOriginals();
                        break;
                }
            }
        });
    </script>
</body>
</html>
EOF

echo -e "${GREEN}✅ Comparison HTML created at $OUTPUT_DIR/comparison.html${NC}"

# Create enhanced HTTP server script
echo -e "${BLUE}� Creating comparison interface...${NC}"

# First, let's create a simple HTTP server script

cat > "$OUTPUT_DIR/start_server.py" << 'EOF'
#!/usr/bin/env python3
import http.server
import socketserver
import os
import sys
import webbrowser
import threading
import time
import socket
import subprocess
import signal

def find_process_using_port(port):
    """Find process ID using the specified port."""
    try:
        # Use lsof to find the process using the port
        result = subprocess.run(['lsof', '-ti', f':{port}'], 
                              capture_output=True, text=True, check=False)
        if result.stdout.strip():
            return int(result.stdout.strip().split('\n')[0])
        return None
    except (subprocess.SubprocessError, ValueError):
        return None

def kill_process_on_port(port):
    """Kill process using the specified port."""
    pid = find_process_using_port(port)
    if pid:
        try:
            print(f"🔍 Found existing server on port {port} (PID: {pid})")
            os.kill(pid, signal.SIGTERM)
            time.sleep(1)  # Give it time to shut down gracefully
            
            # Check if it's still running
            if find_process_using_port(port):
                print(f"⚠️  Process didn't stop gracefully, forcing...")
                os.kill(pid, signal.SIGKILL)
                time.sleep(0.5)
            
            print(f"✅ Stopped existing server (PID: {pid})")
            return True
        except (ProcessLookupError, PermissionError) as e:
            print(f"⚠️  Could not stop process {pid}: {e}")
            return False
    return False

def is_port_available(port):
    """Check if a port is available."""
    try:
        with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
            s.bind(('', port))
            return True
    except OSError:
        return False

def find_available_port(start_port=8080, max_attempts=50):
    """Find an available port starting from start_port."""
    for port in range(start_port, start_port + max_attempts):
        if is_port_available(port):
            return port
    return None

def open_browser_delayed(url, delay=2):
    """Open browser after a delay."""
    time.sleep(delay)
    print(f"🌐 Opening browser: {url}")
    webbrowser.open(url)

def main():
    # Change to the directory containing this script
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    
    print("🏖️ Shoreline Publication Comparison Server")
    print("=" * 45)
    
    # Find an available port
    port = find_available_port()
    if port is None:
        print("❌ Could not find an available port")
        sys.exit(1)
    
    # Kill any existing process on this port
    kill_process_on_port(port)
    
    # Create server
    handler = http.server.SimpleHTTPRequestHandler
    
    try:
        with socketserver.TCPServer(("", port), handler) as httpd:
            url = f"http://localhost:{port}/comparison.html"
            
            print(f"🚀 Server starting on port {port}")
            print(f"📂 Serving from: {os.getcwd()}")
            print(f"🌐 Comparison URL: {url}")
            print(f"📄 Direct access:")
            print(f"   • Version 1: http://localhost:{port}/version1/publication.html")
            print(f"   • Version 2: http://localhost:{port}/version2/publication.html")
            print("")
            print("💡 Press Ctrl+C to stop the server")
            print("=" * 45)
            
            # Open browser in a separate thread
            browser_thread = threading.Thread(target=open_browser_delayed, args=(url,))
            browser_thread.daemon = True
            browser_thread.start()
            
            # Start server
            httpd.serve_forever()
            
    except KeyboardInterrupt:
        print("\n👋 Server stopped by user")
    except Exception as e:
        print(f"❌ Server error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
EOF

chmod +x "$OUTPUT_DIR/start_server.py"
echo -e "${GREEN}✅ HTTP server script created and made executable${NC}"

# Create file size comparison
echo -e "${BLUE}📊 Generating file size comparison...${NC}"

V1_SIZE=$(ls -lh "$OUTPUT_DIR/version1/publication.html" 2>/dev/null | awk '{print $5}' || echo "N/A")
V2_SIZE=$(ls -lh "$OUTPUT_DIR/version2/publication.html" 2>/dev/null | awk '{print $5}' || echo "N/A")

cat > "$OUTPUT_DIR/comparison_stats.txt" << EOF
🏖️ Shoreline Publication Comparison Statistics
=============================================

Site ID: $SITE_ID
Generated: $(date)

Version Comparison:
• Version 1: $VERSION_1
  File size: $V1_SIZE
  Path: version1/publication.html

• Version 2: $VERSION_2  
  File size: $V2_SIZE
  Path: version2/publication.html

Interface.crate Sources:
• Primary: https://github.com/GusEllerm/CoastSat-interface.crate
• Fallback: https://github.com/kvos/CoastSat

Files Generated:
• comparison.html       - Side-by-side comparison interface
• start_server.py       - Local HTTP server for viewing
• comparison_stats.txt  - This statistics file
• version1/            - First publication version
• version2/            - Second publication version

Usage:
1. Start server: python3 start_server.py
2. Open browser: http://localhost:8080/comparison.html
3. Use sync scrolling and fullscreen controls
4. Compare shoreline analysis differences

EOF

echo -e "${GREEN}✅ Comparison statistics saved to $OUTPUT_DIR/comparison_stats.txt${NC}"

# Summary and next steps
echo ""
echo -e "${CYAN}🎉 Comparison Generation Complete!${NC}"
echo "=================================="
echo ""
echo -e "${GREEN}📁 Output Directory: $OUTPUT_DIR${NC}"
echo -e "${GREEN}📄 Comparison Interface: $OUTPUT_DIR/comparison.html${NC}"
echo -e "${GREEN}🌐 Server Script: $OUTPUT_DIR/start_server.py${NC}"
echo -e "${GREEN}📊 Statistics: $OUTPUT_DIR/comparison_stats.txt${NC}"
echo ""
echo -e "${YELLOW}🚀 To view the comparison:${NC}"
echo -e "${BLUE}   cd $OUTPUT_DIR${NC}"
echo -e "${BLUE}   python3 start_server.py${NC}"
echo ""
echo -e "${YELLOW}📊 File Sizes:${NC}"
echo -e "${BLUE}   Version 1 ($VERSION_1): $V1_SIZE${NC}"
echo -e "${BLUE}   Version 2 ($VERSION_2): $V2_SIZE${NC}"
echo ""

# Auto-open if requested
if [ "$AUTO_OPEN" = true ]; then
    echo -e "${YELLOW}🌐 Auto-opening comparison in browser...${NC}"
    cd "$OUTPUT_DIR"
    python3 start_server.py &
    SERVER_PID=$!
    
    # Give server time to start
    sleep 2
    
    # Clean up on exit
    trap "kill $SERVER_PID 2>/dev/null" EXIT
    
    echo -e "${GREEN}✨ Comparison server is running! Press Ctrl+C to stop.${NC}"
    wait $SERVER_PID
else
    echo -e "${YELLOW}💡 Run the server manually when ready to view the comparison.${NC}"
fi

echo -e "${GREEN}✨ Done!${NC}"

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
        let doc1, doc2;
        
        const iframe1 = document.getElementById('iframe1');
        const iframe2 = document.getElementById('iframe2');
        const syncIndicator = document.getElementById('syncIndicator');
        
        function getIframeDocument(iframe) {
            try {
                return iframe.contentDocument || iframe.contentWindow.document;
            } catch (e) {
                console.log('Cannot access iframe content due to security restrictions');
                return null;
            }
        }
        
        function setupSyncScrolling() {
            // Wait for both iframes to load
            let iframe1Loaded = false;
            let iframe2Loaded = false;
            
            iframe1.onload = function() {
                iframe1Loaded = true;
                doc1 = getIframeDocument(iframe1);
                if (iframe1Loaded && iframe2Loaded) {
                    attachScrollListeners();
                }
            };
            
            iframe2.onload = function() {
                iframe2Loaded = true;
                doc2 = getIframeDocument(iframe2);
                if (iframe1Loaded && iframe2Loaded) {
                    attachScrollListeners();
                }
            };
        }
        
        function attachScrollListeners() {
            if (!doc1 || !doc2) {
                console.log('Cannot attach scroll listeners - iframe access restricted');
                // Hide sync indicator if we can't sync
                syncIndicator.style.display = 'none';
                return;
            }
            
            console.log('Setting up synchronized scrolling...');
            
            // Debounce function to smooth out rapid scroll events
            function debounce(func, wait) {
                let timeout;
                return function executedFunction(...args) {
                    const later = () => {
                        clearTimeout(timeout);
                        func(...args);
                    };
                    clearTimeout(timeout);
                    timeout = setTimeout(later, wait);
                };
            }
            
            // Smooth scroll sync function - same speed, not same position
            function syncScroll(sourceDoc, targetDoc) {
                if (!syncEnabled || isScrolling) return;
                
                isScrolling = true;
                
                try {
                    // Get source scroll position (absolute pixels)
                    const sourceScrollTop = sourceDoc.documentElement.scrollTop || sourceDoc.body.scrollTop || 0;
                    
                    // Get target document height info for bounds checking
                    const targetScrollHeight = targetDoc.documentElement.scrollHeight || targetDoc.body.scrollHeight || 1;
                    const targetClientHeight = targetDoc.documentElement.clientHeight || targetDoc.body.clientHeight || 1;
                    const maxTargetScroll = Math.max(0, targetScrollHeight - targetClientHeight);
                    
                    // Use the same absolute scroll position (same speed scrolling)
                    // But cap it at the maximum possible scroll for the target document
                    const targetScrollTop = Math.min(sourceScrollTop, maxTargetScroll);
                    
                    // Apply scroll directly with same pixel position
                    if (targetDoc.documentElement && typeof targetDoc.documentElement.scrollTop !== 'undefined') {
                        targetDoc.documentElement.scrollTop = targetScrollTop;
                    } else if (targetDoc.body) {
                        targetDoc.body.scrollTop = targetScrollTop;
                    }
                    
                    console.log(`Same-speed sync: ${sourceScrollTop}px -> ${targetScrollTop}px (max: ${maxTargetScroll}px)`);
                    
                } catch (e) {
                    console.log('Error syncing scroll:', e);
                }
                
                // Reset scrolling flag after a brief delay
                setTimeout(() => { 
                    isScrolling = false; 
                }, 50);
            }
            
            // Create debounced sync functions
            const syncToDoc2 = debounce(() => syncScroll(doc1, doc2), 16); // ~60fps
            const syncToDoc1 = debounce(() => syncScroll(doc2, doc1), 16);
            
            // Add scroll listeners with improved event handling
            const doc1ScrollHandler = function() {
                if (syncEnabled && !isScrolling) {
                    syncToDoc2();
                }
            };
            
            const doc2ScrollHandler = function() {
                if (syncEnabled && !isScrolling) {
                    syncToDoc1();
                }
            };
            
            doc1.addEventListener('scroll', doc1ScrollHandler, { passive: true });
            doc2.addEventListener('scroll', doc2ScrollHandler, { passive: true });
            
            console.log('Synchronized scrolling enabled with smooth debouncing');
        }
        
        function toggleSync() {
            syncEnabled = !syncEnabled;
            syncIndicator.textContent = syncEnabled ? '🔄 Synchronized Scrolling' : '⏸️ Sync Disabled';
            syncIndicator.className = syncEnabled ? 'sync-indicator' : 'sync-indicator disabled';
            console.log('Sync toggled:', syncEnabled);
        }
        
        function resetView() {
            console.log('Resetting view...');
            
            // Temporarily disable sync to avoid conflicts
            const wasEnabled = syncEnabled;
            syncEnabled = false;
            
            try {
                // Smooth scroll to top for both documents
                if (doc1) {
                    if (doc1.documentElement && typeof doc1.documentElement.scrollTop !== 'undefined') {
                        doc1.documentElement.scrollTo({ top: 0, behavior: 'smooth' });
                    } else if (doc1.body) {
                        doc1.body.scrollTo({ top: 0, behavior: 'smooth' });
                    }
                }
                
                if (doc2) {
                    if (doc2.documentElement && typeof doc2.documentElement.scrollTop !== 'undefined') {
                        doc2.documentElement.scrollTo({ top: 0, behavior: 'smooth' });
                    } else if (doc2.body) {
                        doc2.body.scrollTo({ top: 0, behavior: 'smooth' });
                    }
                }
                
                console.log('View reset successfully with smooth scrolling');
                
                // Re-enable sync after smooth scroll completes
                setTimeout(() => {
                    syncEnabled = wasEnabled;
                }, 1000);
                
            } catch (e) {
                console.log('Cannot reset view - iframe access restricted:', e);
                // Fallback: reload the iframes
                iframe1.src = iframe1.src;
                iframe2.src = iframe2.src;
                console.log('Reloaded iframes as fallback');
                
                // Re-enable sync immediately for fallback
                syncEnabled = wasEnabled;
            }
        }
        
        function openOriginals() {
            console.log('Opening original publications...');
            window.open('version1/publication.html', '_blank');
            window.open('version2/publication.html', '_blank');
        }
        
        // Initialize everything
        setupSyncScrolling();
        
        // Add some debug info
        console.log('Publication comparison interface loaded');
        console.log('Sync enabled:', syncEnabled);
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
- $OUTPUT_DIR/start_server.py        (HTTP server for secure comparison viewing)
- $OUTPUT_DIR/comparison_report.txt   (This report)

Usage:
------
To view the comparison interface with full functionality:

1. Start the HTTP server:
   cd $OUTPUT_DIR && python3 start_server.py --open

2. The comparison will open automatically at http://localhost:8000/comparison.html

3. Features available:
   - Side-by-side publication comparison
   - Synchronized scrolling between versions
   - Toggle controls for sync/reset/open originals

Technical Notes:
---------------
- HTTP server is used to avoid browser same-origin policy restrictions
- Direct file:// access may have limited JavaScript functionality
- Server runs on localhost:8000 for secure local access

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
# Get file sizes for comparison report
if [ -f "$OUTPUT_DIR/version1/publication.html" ] && [ -f "$OUTPUT_DIR/version2/publication.html" ]; then
    SIZE_1=$(ls -lh "$OUTPUT_DIR/version1/publication.html" | awk '{print $5}')
    SIZE_2=$(ls -lh "$OUTPUT_DIR/version2/publication.html" | awk '{print $5}')
    
    echo ""
    echo -e "${CYAN}📊 File size comparison:${NC}"
    echo "   Version 1 ($VERSION_1): $SIZE_1"
    echo "   Version 2 ($VERSION_2): $SIZE_2"
fi

echo -e "${GREEN}✅ Comparison interface created successfully!${NC}"
echo ""

if [ "$AUTO_OPEN" = true ]; then
    echo "🚀 Starting HTTP server and opening comparison interface..."
    echo "📝 Note: Using HTTP server to avoid browser security restrictions"
    echo ""
    
    # Check if port 8000 is already in use and offer to clean it up
    if lsof -ti :8000 >/dev/null 2>&1; then
        echo "⚠️  Port 8000 appears to be in use (likely from a previous comparison)"
        echo "🔧 The server will automatically handle this and use an available port"
        echo ""
    fi
    
    # Start the server with auto-open
    cd "$OUTPUT_DIR"
    python3 start_server.py --open &
    SERVER_PID=$!
    
    # Wait a moment for the server to start and determine the port
    sleep 2
    
    # Try to determine what port is being used
    ACTUAL_PORT=$(lsof -ti :8000 >/dev/null 2>&1 && echo "8000" || (
        for port in 8001 8002 8003 8004 8005; do
            if lsof -ti :$port >/dev/null 2>&1; then
                echo "$port"
                break
            fi
        done
    ))
    
    if [ -n "$ACTUAL_PORT" ]; then
        echo "✅ Server started (PID: $SERVER_PID) on port $ACTUAL_PORT"
        echo "🌐 Comparison available at: http://localhost:$ACTUAL_PORT/comparison.html"
    else
        echo "✅ Server started (PID: $SERVER_PID)"
        echo "🌐 Check the server output above for the actual port number"
    fi
    
    echo ""
    echo "💡 To stop the server later:"
    echo "   Method 1: kill $SERVER_PID"
    echo "   Method 2: Press Ctrl+C in the server terminal"
    echo "   Method 3: Close the browser tab (server will continue but you can stop it manually)"
    
    # Go back to original directory
    cd - > /dev/null
else
    echo "ℹ️  Auto-open disabled. To view the comparison:"
    echo ""
    echo "Option 1 - Start HTTP server (recommended):"
    echo "   cd $OUTPUT_DIR && python3 start_server.py --open"
    echo ""
    echo "Option 2 - Direct file access (may have limitations):"
    echo "   file://$(pwd)/$OUTPUT_DIR/comparison.html"
    echo ""
    echo "💡 The HTTP server option avoids browser security restrictions"
    echo "   and will automatically handle port conflicts if they occur"
fi

echo ""
echo "🎯 Next steps:"
echo "   • The comparison interface will open automatically in your browser"
echo "   • Scroll through both publications to compare differences"
echo "   • Use the toggle sync button to enable/disable synchronized scrolling"
echo "   • Click 'Open Originals' to view publications in separate tabs"
echo "   • Check the comparison report for file size differences"
echo ""
echo "🔧 Technical notes:"
echo "   • HTTP server runs on localhost:8000 to avoid browser security restrictions"
echo "   • Server will continue running until you stop it (Ctrl+C)"
echo "   • All files are served locally from your machine"
