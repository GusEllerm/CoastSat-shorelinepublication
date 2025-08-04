# Narrative Zones for Shoreline Publication

## Overview

Based on analysis of the transect data, we've identified 9 distinct narrative zone types that can be automatically detected and used to generate meaningful stories about shoreline behavior. Each zone type has an assigned priority level that determines the order of classification and can optionally be used to sort results by importance.

## Zone Types and Characteristics

The zones are listed below in **priority order** (priority 1 = highest importance):

### 1. **No Data Zone** (Priority 1)

- **Trigger**: Missing trend data
- **Significance**: Areas lacking sufficient observations
- **Narrative**: "No data zone spanning X.Xkm where insufficient observations prevent trend analysis."

### 2. **Rapid Erosion Zone** (Priority 2)

- **Trigger**: Trend < -0.8 m/year
- **Significance**: Critical areas requiring immediate attention
- **Narrative**: "Critical erosion hotspot spanning X.Xkm with average retreat of X.Xm/year. This area requires immediate attention and monitoring."

### 3. **Moderate Erosion Zone** (Priority 3)

- **Trigger**: -0.8 ≤ Trend < -0.3 m/year
- **Significance**: Ongoing erosion processes that need monitoring
- **Narrative**: "Erosion zone extending X.Xkm showing consistent retreat averaging X.Xm/year. Ongoing erosion processes are evident."

### 4. **Rapid Accretion Zone** (Priority 4)

- **Trigger**: Trend > 0.8 m/year
- **Significance**: Areas of significant sediment accumulation
- **Narrative**: "Dynamic accretion zone over X.Xkm with significant sand accumulation averaging X.Xm/year. This area shows strong sediment deposition."

### 5. **Moderate Accretion Zone** (Priority 5)

- **Trigger**: 0.3 < Trend ≤ 0.8 m/year
- **Significance**: Stable areas with positive sediment balance
- **Narrative**: "Stable accretion zone spanning X.Xkm with gradual beach building averaging X.Xm/year. Positive sediment balance is maintained."

### 6. **High Uncertainty Zone** (Priority 6)

- **Trigger**: R² score < 0.05 OR RMSE > 30m
- **Significance**: Areas where data quality is poor and trends are unreliable
- **Narrative**: "Data-limited zone over X.Xkm where shoreline trends are difficult to determine reliably. Additional monitoring may be needed."

### 7. **Steep Beach Zone** (Priority 7)

- **Trigger**: Beach slope > 0.08
- **Significance**: High-energy environments vulnerable to storm impacts
- **Narrative**: "High-energy beach zone over X.Xkm characterized by steep beach profiles. This area may be vulnerable to storm impacts."

### 8. **Low Energy Zone** (Priority 8)

- **Trigger**: Beach slope < 0.04
- **Significance**: Protected or low-energy environments
- **Narrative**: "Protected shoreline segment spanning X.Xkm with gentle beach profiles indicating low wave energy conditions."

### 9. **Stable Zone** (Priority 9)

- **Trigger**: -0.3 ≤ Trend ≤ 0.3 m/year (and not caught by other criteria)
- **Significance**: Areas in equilibrium with minimal change
- **Narrative**: "Stable shoreline segment extending X.Xkm showing minimal change over time. This area exhibits natural equilibrium."

## Zone Detection Algorithm

The algorithm processes transects sequentially and:

1. **Classifies each transect** using the priority hierarchy above (lower priority numbers = higher importance)
2. **Groups adjacent transects** of the same type into zones
3. **Applies minimum zone length** (default: 3 transects) to filter out noise
4. **Calculates zone statistics** including length, average properties, and extents
5. **Generates narrative descriptions** with specific metrics
6. **Optionally sorts zones** by priority (most important first) or maintains spatial order

### Zone Ordering Options

The analysis supports two ordering modes:

- **Spatial Order (default)**: Zones are returned in the order they appear along the coastline from start to end
- **Priority Order**: Zones are sorted by importance, with critical erosion zones first and stable zones last

This can be controlled via:
- Command line: `--sort-by-priority` flag
- Programmatically: `sort_by_priority=True` parameter

### Priority-Based Classification

During individual transect classification, zones are evaluated in priority order to ensure that more critical conditions (like rapid erosion) take precedence over less critical ones (like stable conditions). This prevents a transect that meets multiple criteria from being misclassified into a lower-priority zone.

## Key Properties Used

- **trend**: Rate of shoreline change (m/year) - primary classification metric
- **beach_slope**: Beach profile steepness - secondary classification for energy environment
- **r2_score**: Quality of trend fit - identifies uncertain data
- **rmse**: Root mean square error - additional uncertainty indicator
- **along_dist**: Distance along shore - used for zone extents and lengths

## Example Output

From site aus0001:

- **10 zones identified** over 16.8km of shoreline
- **Zone types**: 4 Moderate Accretion, 3 High Uncertainty, 2 Moderate Erosion, 1 Rapid Accretion
- **Longest zone**: 6.3km High Uncertainty zone (poor data quality)
- **Most dynamic**: 1.6km Rapid Accretion zone (0.9m/year advance)

## Integration with Publication Template

This logic can be integrated into `templates/shoreline_publication.smd` by:

1. Loading transects for the site_id
2. Running the zone identification algorithm with optional priority sorting
3. Generating narrative sections for each significant zone
4. Creating maps and visualizations highlighting zone boundaries
5. Providing quantitative summaries and trend analysis

The zones provide a natural structure for organizing the publication narrative. When using priority sorting, the most critical areas (rapid erosion, data gaps) are presented first, followed by dynamic areas (accretion), and finally stable areas. When using spatial sorting, zones are presented in geographic order along the coast.

### Usage Examples

**Command Line:**
```bash
# Priority order (critical zones first)
python narrative_zoning.py aus0001 transects.geojson --sort-by-priority

# Spatial order (geographic sequence)
python narrative_zoning.py aus0001 transects.geojson
```

**Programmatic:**
```python
from narrative_zoning import run_narrative_zoning

# Priority order for management reports
result = run_narrative_zoning("aus0001", "transects.geojson", sort_by_priority=True)

# Spatial order for geographic narratives
result = run_narrative_zoning("aus0001", "transects.geojson", sort_by_priority=False)
```
