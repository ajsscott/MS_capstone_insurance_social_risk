
# Auto Insurance Risk Prediction with Gradient Boosting

## Overview
This project builds a **comprehensive machine learning pipeline** to predict auto insurance risk by combining **NYC Open Data Motor Vehicle Collisions (MVC)** and **ACS socio-economic data** via APIs. We apply **gradient boosting models (XGBoost and LightGBM)** and **SHAP explainability** to uncover key demographic and transportation-related factors influencing crash-related risks. The project highlights **API-driven ETL, explainable AI, and advanced visualizations** as part of the deliverables.

---

## Research Question
**Which socio-economic and transportation-related features most strongly influence auto insurance risk outcomes in New York City?**

---

## Features
- **API-Driven ETL Pipeline:** Automated data ingestion from NYC Open Data and U.S. Census Bureau APIs, orchestrated with Prefect.
- **Machine Learning:** Gradient boosting models (XGBoost/LightGBM) with hyperparameter tuning (Optuna).
- **Explainability:** SHAP-based analysis with force plots, decision plots, and feature importance rankings.
- **Advanced Visualizations:**  
  - Interactive geospatial dashboards (Folium/Plotly).  
  - Time-lapse crash density animations (Kepler.gl/Plotly).  
  - SHAP dashboards for local vs. global feature analysis.  
  - 3D risk visualizations using Plotly or Pydeck.

---

## Deliverables
1. **API-driven ETL Pipeline:** Python scripts with Prefect orchestration.  
2. **Feature Engineering and Modeling Scripts:** For XGBoost/LightGBM training and evaluation.  
3. **Explainability Reports:** SHAP visualizations and feature-level analysis.  
4. **Advanced Visualization Suite:** Geospatial dashboards, time-lapse animations, and SHAP exploration tools.  
5. **Interactive Risk Segmentation Dashboard:** Plotly Dash app for borough-level risk exploration.  
6. **Technical Report & Executive Summary:** Detailed findings and insurance implications.

---

## Tech Stack
- **Languages & Libraries:** Python, pandas, scikit-learn, XGBoost, LightGBM, SHAP, Plotly, Folium, Pydeck.  
- **Data Engineering:** Prefect, Dask, or PySpark for scalable ETL.  
- **Data Sources:** NYC Open Data (MVC), ACS 5-Year API.  
- **Visualization:** Plotly Dash, Kepler.gl, SHAP interactive plots.  
