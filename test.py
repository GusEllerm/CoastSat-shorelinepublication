#!/usr/bin/env python3
"""
Test script for developing narrative zoning logic for shoreline publication.

This script loads transects for a given site_id and will be used to develop
logic for creating "narrative zones" - groups of adjacent transects with
interesting characteristics.
"""

import json
import sys
from typing import List, Dict, Any
import argparse


def load_transects_for_site(site_id: str, transects_file: str = "CoastSat/transects_extended.geojson") -> List[Dict[str, Any]]:
    """
    Load and filter transects for a specific site_id.
    
    Args:
        site_id: The site identifier to filter by (e.g., 'aus0001')
        transects_file: Path to the transects GeoJSON file
        
    Returns:
        List of transect features for the specified site
    """
    try:
        with open(transects_file, 'r') as f:
            data = json.load(f)
        
        # Filter features by site_id
        site_transects = [
            feature for feature in data['features'] 
            if feature['properties']['site_id'] == site_id
        ]
        
        # Sort by transect ID to ensure proper ordering
        site_transects.sort(key=lambda x: x['properties']['id'])
        
        return site_transects
        
    except FileNotFoundError:
        print(f"Error: Could not find transects file: {transects_file}")
        sys.exit(1)
    except json.JSONDecodeError:
        print(f"Error: Invalid JSON in file: {transects_file}")
        sys.exit(1)
    except Exception as e:
        print(f"Error loading transects: {e}")
        sys.exit(1)


def print_transect_summary(transects: List[Dict[str, Any]]) -> None:
    """Print a summary of the loaded transects."""
    if not transects:
        print("No transects found for the specified site_id")
        return
    
    site_id = transects[0]['properties']['site_id']
    print(f"\nTransects Summary for site: {site_id}")
    print(f"Total transects: {len(transects)}")
    
    # Extract key properties for analysis
    properties = []
    for transect in transects:
        props = transect['properties']
        properties.append({
            'id': props['id'],
            'along_dist': props['along_dist'],
            'beach_slope': props['beach_slope'],
            'trend': props['trend'],
            'r2_score': props['r2_score'],
            'orientation': props['orientation']
        })
    
    # Print first few and last few transects
    print(f"\nFirst 3 transects:")
    for i, prop in enumerate(properties[:3]):
        print(f"  {i+1}. ID: {prop['id']}, Distance: {prop['along_dist']:.1f}m, "
              f"Slope: {prop['beach_slope']}, Trend: {prop['trend']:.3f}")
    
    if len(properties) > 6:
        print("  ...")
        
    if len(properties) > 3:
        print(f"\nLast 3 transects:")
        for i, prop in enumerate(properties[-3:], len(properties)-2):
            print(f"  {i}. ID: {prop['id']}, Distance: {prop['along_dist']:.1f}m, "
                  f"Slope: {prop['beach_slope']}, Trend: {prop['trend']:.3f}")


def analyze_transect_properties(transects: List[Dict[str, Any]]) -> Dict[str, Any]:
    """
    Analyze transect properties to identify potential narrative zones.
    
    This function will be expanded to implement the narrative zoning logic.
    """
    if not transects:
        return {}
    
    # Extract numeric properties for analysis
    beach_slopes = [t['properties']['beach_slope'] for t in transects if t['properties']['beach_slope'] is not None]
    trends = [t['properties']['trend'] for t in transects if t['properties']['trend'] is not None]
    r2_scores = [t['properties']['r2_score'] for t in transects if t['properties']['r2_score'] is not None]
    
    analysis = {
        'count': len(transects),
        'beach_slope': {
            'min': min(beach_slopes) if beach_slopes else None,
            'max': max(beach_slopes) if beach_slopes else None,
            'avg': sum(beach_slopes) / len(beach_slopes) if beach_slopes else None
        },
        'trend': {
            'min': min(trends) if trends else None,
            'max': max(trends) if trends else None,
            'avg': sum(trends) / len(trends) if trends else None
        },
        'r2_score': {
            'min': min(r2_scores) if r2_scores else None,
            'max': max(r2_scores) if r2_scores else None,
            'avg': sum(r2_scores) / len(r2_scores) if r2_scores else None
        }
    }
    
    return analysis


def main():
    """Main function to test transect loading and analysis."""
    parser = argparse.ArgumentParser(description='Test narrative zoning logic for shoreline transects')
    parser.add_argument('site_id', help='Site ID to analyze (e.g., aus0001)')
    parser.add_argument('--transects-file', default='CoastSat/transects_extended.geojson',
                       help='Path to transects GeoJSON file')
    
    args = parser.parse_args()
    
    print(f"Loading transects for site: {args.site_id}")
    
    # Load transects for the specified site
    transects = load_transects_for_site(args.site_id, args.transects_file)
    
    # Print summary
    print_transect_summary(transects)
    
    # Analyze properties
    analysis = analyze_transect_properties(transects)
    
    if analysis:
        print(f"\nProperty Analysis:")
        print(f"Beach Slope - Min: {analysis['beach_slope']['min']}, "
              f"Max: {analysis['beach_slope']['max']}, "
              f"Avg: {analysis['beach_slope']['avg']:.3f}")
        print(f"Trend - Min: {analysis['trend']['min']:.3f}, "
              f"Max: {analysis['trend']['max']:.3f}, "
              f"Avg: {analysis['trend']['avg']:.3f}")
        print(f"R² Score - Min: {analysis['r2_score']['min']:.3f}, "
              f"Max: {analysis['r2_score']['max']:.3f}, "
              f"Avg: {analysis['r2_score']['avg']:.3f}")
    
    print(f"\n--- Ready for narrative zoning logic development ---")
    print(f"Next steps:")
    print(f"1. Implement functions to identify zones based on property thresholds")
    print(f"2. Create logic to group adjacent transects with similar characteristics") 
    print(f"3. Define what makes a zone 'interesting' or narratively significant")
    
    return transects


if __name__ == "__main__":
    main()
