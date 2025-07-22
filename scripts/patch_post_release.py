import sys
from pathlib import Path
from rocrate.rocrate import ROCrate

if len(sys.argv) != 2:
    print("Usage: python patch_post_release.py <release_url>")
    sys.exit(1)

release_url = sys.argv[1]
print(f"🔧 Patching publication.crate with release URL: {release_url}")

# Dynamically resolve path to publication.crate/ relative to project root (parent of scripts)
SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SCRIPT_DIR.parent  # Go up one level from scripts/ to project root
CRATE_DIR = PROJECT_ROOT / "publication.crate"

print(f"📁 Loading crate from: {CRATE_DIR}")

if not CRATE_DIR.exists():
    print(f"❌ publication.crate not found at {CRATE_DIR}")
    print(f"💡 Script is in: {SCRIPT_DIR}")
    print(f"💡 Project root: {PROJECT_ROOT}")
    sys.exit(1)

interface_crate = ROCrate(str(CRATE_DIR))

if interface_crate.mainEntity:
    print(f"✅ Found mainEntity: {interface_crate.mainEntity.id}")
    interface_crate.mainEntity["url"] = release_url
    print(f"🔗 Updated URL to: {release_url}")
else:
    print("❌ mainEntity not found in the crate.")
    sys.exit(1)

print("💾 Writing updated crate...")
interface_crate.write(str(CRATE_DIR))
print("✅ Successfully patched publication.crate with release URL")