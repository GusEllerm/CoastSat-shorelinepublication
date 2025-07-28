#!/usr/bin/env python3
"""
Test script for narrative_zoning.run_narrative_zoning
"""
import json
from src.narrative_zoning import run_narrative_zoning, get_default_zone_definitions

SITE_ID = "aus0001"
TRANSECTS_FILE = "publication.crate/cached_primary_result.geojson"

if __name__ == "__main__":
    zone_definitions = get_default_zone_definitions()
    result = run_narrative_zoning(SITE_ID, TRANSECTS_FILE, min_zone_length=3, zone_definitions=zone_definitions)
    print(json.dumps(result, indent=2, ensure_ascii=False))
