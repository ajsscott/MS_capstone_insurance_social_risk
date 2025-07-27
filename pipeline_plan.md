
# Gradient Boosting Pipeline for Auto Insurance Risk Prediction

## Overview
This project builds an **end-to-end machine learning pipeline** to predict auto insurance risk using **NYC Open Data Motor Vehicle Collisions (MVC)** and **ACS 5-Year socio-economic data** accessed via APIs. The pipeline leverages **gradient boosting models (XGBoost/LightGBM)** and **SHAP explainability** to identify which demographic and behavioral features drive crash-related risk outcomes. From ingestion to interpretability, this project demonstrates **API-based ETL, scalable data engineering, hyperparameter tuning, and model explainability**—all highly in-demand skills.

---

## Research Question
**Which socio-economic and transportation-related features (e.g., income, commuting behavior, vehicle ownership) most strongly influence crash-related insurance risk outcomes in New York City?**

---

## Pipeline Design (Skills-Oriented)
### **Phase 1: Data Acquisition (API-Driven ETL)**
- **API Integration:**  
  - Use the **NYC Open Data API** (Socrata) to pull MVC datasets (2018–2023).  
  - Use the **U.S. Census Bureau API** for ACS 5-Year data (e.g., income, vehicle availability, commute modes).
- **Incremental Ingestion:** Design ETL to fetch new data incrementally and store in a version-controlled data lake (AWS S3 or local staging).
- **Data Engineering Tools:** Automate ingestion with Python scripts and Prefect (or Airflow) for scheduling.

---

### **Phase 2: Data Cleaning & Transformation**
- **Big Data Wrangling:** Use **Dask** or **PySpark** to handle large-scale crash records efficiently.
- **Geospatial Joins:** Map crashes to boroughs or census tracts for spatial aggregation.
- **Feature Harmonization:** Align ACS socio-economic features with crash data by GEOID/borough mapping.

---

### **Phase 3: Feature Engineering**

* **Crash and Severity Proxies:**

  * Calculate **crashes per 1,000 residents** (normalized by population) as a proxy for claim frequency.
  * Compute **injury-to-fatality ratios** from crash records to approximate claim severity.
* **Socio-Economic Features (ACS):**

  * Extract **median income, age distribution, education levels, commute modes, vehicle ownership, household size, population density, and occupancy patterns** from ACS 5-year data (2018–2022).
  * Apply **log-transformations** on density and other non-linear variables to capture scaling effects.
* **Spatial Integration & Derived Metrics:**

  * Spatially join crash records with ACS NTAs using NYC Open Data shapefiles.
  * Derive **vehicle ownership ratios** and interaction terms (e.g., car ownership × income).
* **Data Preprocessing:**

  * Remove outliers (e.g., abnormal crash counts) using **interquartile range thresholds**.
  * Impute missing values with **median imputation**.
  * **One-hot encode** categorical variables (e.g., commute modes).
  * **Standardize** continuous variables for model input.

---

### **Phase 4: Modeling**

* **Gradient Boosting Models:**

  * Train **XGBoost** and **LightGBM** models on integrated crash + socio-economic data.
  * Focus on predicting **frequency and severity proxies** using mixed categorical and continuous features.
* **Hyperparameter Optimization:**

  * Use **Optuna** (Bayesian search + pruning) to tune model hyperparameters for optimal accuracy.
* **Model Validation:**

  * Evaluate predictive performance using **AUC and F1-score** for classification tasks (frequency risk tiers).
  * Use **RMSE and MAE** for regression tasks (severity metrics).

---

### **Phase 5: Explainability**

* **SHAP Analysis:**

  * Apply **SHAP (Shapley Additive Explanations)** to interpret both global and local model predictions.
  * Generate **SHAP summary plots, dependence plots, and feature attribution reports** to show how socio-economic factors (e.g., income, commute patterns, vehicle ownership) drive risk predictions.

---

### **Phase 6: Visualization & Insights**
- **Interactive Maps:** Visualize crash risk and socio-economic features by borough/tract (e.g., Folium or Plotly).
- **Dashboards:** Create a **Plotly Dash dashboard** summarizing key results.
- **Narrative Reporting:** Summarize the predictive findings and insurance implications.

---

## **Deliverables**

1. **API-driven ETL Pipeline:** Python scripts (with Prefect orchestration) for ingesting and cleaning NYC crash and ACS data.
2. **Feature Engineering and Modeling Scripts:** Modular code for XGBoost/LightGBM training, evaluation, and hyperparameter optimization.
3. **Explainability Reports:** SHAP-based visualizations, including force plots, decision plots, and feature importance rankings.
4. **Advanced Visualization Suite:**
   * **Interactive Geospatial Dashboards** using Folium/Plotly (borough-level risk maps and crash hotspots).
   * **Interactive SHAP Dashboard** (built with Dash/Panel) for local vs. global feature importance exploration.
5. **Interactive Risk Segmentation Dashboard:** A Plotly Dash app to explore borough-level risk and socio-economic drivers dynamically.
6. **Technical Report & Executive Summary:** Methodology, findings, and insurance implications, with embedded visual narratives.

---

## Skills Demonstrated
- **Machine Learning:** Gradient Boosting (XGBoost/LightGBM), clustering, SHAP explainability.
- **Data Engineering:** API ingestion (NYC Open Data API, U.S. Census Bureau API), ETL orchestration (Prefect), Dask/PySpark for scalable wrangling.
- **Cloud & Storage:** AWS S3 (optional for storing raw and processed data).
- **Visualization & BI:** Plotly Dash, Folium maps, SHAP plots.
- **Geospatial & Socio-Economic Analytics:** Mapping crash patterns with ACS socio-demographics.
