# Bayesian Social Risk Modeling for Insurance Applications in NYC

## Overview

This project builds a Bayesian spatial model to estimate area-level insurance-relevant risk in New York City, based on social vulnerability indicators from the American Community Survey (ACS) and historical traffic crash statistics from NYC Open Data. It aims to identify census tracts with elevated latent risk—such as accident exposure or underinsurance likelihood—driven by socioeconomic and demographic factors.

The final output includes:
- A fully Bayesian hierarchical model with spatial random effects
- An interactive map and dashboard visualizing tract-level risk estimates with uncertainty
- A replicable pipeline demonstrating applied insurance analytics using public data

---

## Objectives

- Quantify how social and demographic factors contribute to variation in insurance-relevant risks
- Model latent "social risk" using ACS data and observed motor vehicle crash data
- Demonstrate Bayesian hierarchical and spatial modeling techniques
- Surface equity-relevant insights for insurers, risk managers, and public agencies

---

## Data Sources

| Dataset | Source | Description |
|--------|--------|-------------|
| ACS 2023 | US Census Bureau | Tract-level demographics, poverty, housing, commuting, insurance coverage |
| NYC Motor Vehicle Collisions | NYC Open Data | Geolocated crash records with time, injury counts, and contributing factors |

---

## Target Variables

**Outcome**:  
- Crash incidents per 1,000 residents by census tract (aggregated from NYC crash data)

**Predictors** (ACS-derived):  
- % without health insurance  
- % in poverty  
- % of residents with a disability  
- % of households without a vehicle  
- % with commute over 60 minutes  
- % over age 65  
- % in single-parent households  
- Median household income  

---

## Methodology

- Build a tract-level dataset joining ACS predictors with aggregated crash data  
- Specify a **Bayesian hierarchical spatial model** using a Poisson or Gaussian likelihood depending on crash count distribution
- Include:
  - Tract-level fixed effects for social factors
  - Borough-level random intercepts
  - Spatially structured error terms (e.g., ICAR prior)
- Estimate posterior distributions and credible intervals for all tract-level risk scores

---

## Tools & Technologies

- **R**: `brms`, `tidyverse`, `sf`, `tigris`, `spdep` 
- **Mapping**: Choropleths using `leaflet` or `folium`

---

## Sample Dashboard Metrics

- Estimated tract-level social insurance risk score (posterior mean + uncertainty)
- Top 10 tracts by predicted latent risk
- Spatial clusters of elevated crash rates
- Correlation matrix: social factors vs. crash density

---

## 👤 Author

**AJ Strauman-Scott**  
Data Scientist | Storyteller | ML & Geospatial Modeling  
[LinkedIn](https://linkedin.com/in/ajstraumanscott) | [GitHub](https://github.com/ajsscott)
