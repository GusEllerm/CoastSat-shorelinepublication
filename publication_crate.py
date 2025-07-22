#!/usr/bin/env python3
"""
Backward compatibility wrapper for publication_crate.py
This script maintains compatibility while the main logic has moved to src/publication_logic.py
"""

import sys
from pathlib import Path

# Add src directory to Python path
src_dir = Path(__file__).parent / "src"
sys.path.insert(0, str(src_dir))

# Import and run the main publication logic
if __name__ == "__main__":
    import subprocess
    result = subprocess.run([sys.executable, str(src_dir / "publication_logic.py")] + sys.argv[1:])
    sys.exit(result.returncode)
