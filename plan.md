# Project Plan: Bayesian Social Risk Modeling for Insurance

## Goal

To model the latent insurance-relevant risk exposure of NYC census tracts by linking ACS-based social vulnerability factors with observed crash rates. The model will inform how social determinants correlate with risk across space and allow for uncertainty-aware comparisons between neighborhoods.

---

## Phases

### Phase 1: Data Acquisition & Cleaning
- [ ] Download 2023 ACS 5-Year data at tract level for NYC (already complete)
- [ ] Download NYC Open Data motor vehicle collision dataset
- [ ] Clean and geocode crash data; aggregate total crashes and crash rate per 1,000 residents by tract
- [ ] Join ACS and crash data by census tract GEOID

### Phase 2: Feature Engineering
- [ ] Select key ACS predictors relevant to insurance risk
- [ ] Normalize or transform skewed variables (e.g., log-transform household income)
- [ ] Create borough ID for hierarchical grouping
- [ ] Compute spatial neighbor structure for tracts (adjacency matrix)

### Phase 3: Modeling
- [ ] Fit Bayesian Poisson (or Gaussian) model with:
  - ACS predictors as fixed effects
  - Borough random intercepts
  - Conditional autoregressive (CAR) spatial error term
- [ ] Validate model using posterior predictive checks
- [ ] Summarize posterior distributions: means, SDs, 95% credible intervals

### Phase 4: Visualization & Communication
- [ ] Generate choropleths of predicted risk and uncertainty
- [ ] Highlight tracts with high predicted risk but low crash counts (underreported risk)
- [ ] Build an interactive Streamlit or Tableau dashboard

---

## Deliverables

- Final R or Python notebook with full modeling pipeline
- Public GitHub repository with cleaned data and code
- Written summary or blog post explaining modeling decisions
- Interactive dashboard for exploratory use

---

## Key Skills Demonstrated

- Bayesian hierarchical modeling  
- Spatial econometrics with CAR priors  
- ACS data engineering and transformation  
- Public sector insurance risk analysis  
- Uncertainty-aware geospatial analytics  

---

## Timeline (Suggested)

| Week | Milestone |
|------|-----------|
| 1 | Finalize predictors, acquire + clean crash data |
| 2 | Join datasets, begin modeling |
| 3 | Tune priors, evaluate convergence |
| 4 | Visualizations, dashboard, documentation |
