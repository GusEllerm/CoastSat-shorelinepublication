# Narrative Zones for Shoreline Publication

## Overview

Based on analysis of the transect data, we've identified 9 distinct narrative zone types that can be automatically detected and used to generate meaningful stories about shoreline behavior.

## Zone Types and Characteristics

### 1. **Rapid Erosion Zone**

- **Trigger**: Trend < -0.8 m/year
- **Significance**: Critical areas requiring immediate attention
- **Narrative**: "Critical erosion hotspot spanning X.Xkm with average retreat of X.Xm/year. This area requires immediate attention and monitoring."

### 2. **Moderate Erosion Zone**

- **Trigger**: -0.8 ≤ Trend < -0.3 m/year
- **Significance**: Ongoing erosion processes that need monitoring
- **Narrative**: "Erosion zone extending X.Xkm showing consistent retreat averaging X.Xm/year. Ongoing erosion processes are evident."

### 3. **Rapid Accretion Zone**

- **Trigger**: Trend > 0.8 m/year
- **Significance**: Areas of significant sediment accumulation
- **Narrative**: "Dynamic accretion zone over X.Xkm with significant sand accumulation averaging X.Xm/year. This area shows strong sediment deposition."

### 4. **Moderate Accretion Zone**

- **Trigger**: 0.3 < Trend ≤ 0.8 m/year
- **Significance**: Stable areas with positive sediment balance
- **Narrative**: "Stable accretion zone spanning X.Xkm with gradual beach building averaging X.Xm/year. Positive sediment balance is maintained."

### 5. **High Uncertainty Zone**

- **Trigger**: R² score < 0.05 OR RMSE > 30m
- **Significance**: Areas where data quality is poor and trends are unreliable
- **Narrative**: "Data-limited zone over X.Xkm where shoreline trends are difficult to determine reliably. Additional monitoring may be needed."

### 6. **Steep Beach Zone**

- **Trigger**: Beach slope > 0.08
- **Significance**: High-energy environments vulnerable to storm impacts
- **Narrative**: "High-energy beach zone over X.Xkm characterized by steep beach profiles. This area may be vulnerable to storm impacts."

### 7. **Low Energy Zone**

- **Trigger**: Beach slope < 0.04
- **Significance**: Protected or low-energy environments
- **Narrative**: "Protected shoreline segment spanning X.Xkm with gentle beach profiles indicating low wave energy conditions."

### 8. **Stable Zone**

- **Trigger**: -0.3 ≤ Trend ≤ 0.3 m/year (and not caught by other criteria)
- **Significance**: Areas in equilibrium with minimal change
- **Narrative**: "Stable shoreline segment extending X.Xkm showing minimal change over time. This area exhibits natural equilibrium."

### 9. **No Data Zone**

- **pytTrigger**: Missing trend data
- **Significance**: Areas lacking sufficient observations
- **Narrative**: "No data zone spanning X.Xkm where insufficient observations prevent trend analysis."

## Zone Detection Algorithm

The algorithm processes transects sequentially and:

1. **Classifies each transect** using the hierarchy above (priority order matters)
2. **Groups adjacent transects** of the same type into zones
3. **Applies minimum zone length** (default: 3 transects) to filter out noise
4. **Calculates zone statistics** including length, average properties, and extents
5. **Generates narrative descriptions** with specific metrics

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
2. Running the zone identification algorithm
3. Generating narrative sections for each significant zone
4. Creating maps and visualizations highlighting zone boundaries
5. Providing quantitative summaries and trend analysis

The zones provide a natural structure for organizing the publication narrative, moving from critical areas (rapid erosion) to stable areas, with appropriate detail based on zone significance and data quality.
