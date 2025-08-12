# **Auto Insurance Risk Prediction with Gradient Boosting**

## **Overview**

This project investigates auto insurance risk proxies by predicting crash rates using publicly available data. We integrated **NYC Motor Vehicle Collisions (MVC)** data (2018–2023) with **ACS socio-economic indicators**, collected via **API calls using R scripts**.
Key tasks included:

* **Exploratory Data Analysis (EDA):** Trend analysis, geospatial heatmaps, and descriptive statistics.
* **Modeling:** XGBoost regression optimized with Optuna hyperparameter tuning.
* **Explainability:** SHAP analysis to identify key socio-economic and transportation-related predictors.

---

## Author
AJ Strauman-Scott
Data Scientist | Storyteller | ML & Geospatial Modeling
ajstraumanscott@pm.me
[LinkedIn](www.linkedin.com/in/ajstraumanscott) • [GitHub](https://github.com/ajsscott)

##  Quick Links
-  [Presentation of Results](./straumanscott_resilience-gentrification-NYC-presentation.pdf)
-  [Academic Report](./straumanscott_resilience-gentrification-NYC-report.pdf)
-  [Code & Notebooks](./notebooks)
-  [Source Scripts](./R)

---

## **Research Question**

**Which socio-economic and transportation factors are most predictive of neighborhood-level crash risk in New York City?**

---

## **Key Steps**

* **Data Collection:**

  * Fetched MVC data from NYC Open Data API and ACS 5-year data from the Census Bureau API.
* **Preprocessing:**

  * Aggregated crashes to the census tract level and normalized per 1,000 residents.
  * Harmonized ACS variables to 2020 tract boundaries, binned features, and engineered interaction terms (e.g., poverty × vehicle ownership).
  * Log-transformed crash counts to stabilize variance.
* **EDA:**

  * Created borough-level crash trends and heatmaps (2018 vs. 2022).
  * Summarized key variables (e.g., median income, rent, poverty rates).
* **Modeling:**

  * Trained XGBoost model with spatial cross-validation by borough.
  * Hyperparameters tuned using Optuna.
  * Evaluated performance (R²=0.43, RMSE=0.34).
* **Explainability:**

  * Generated SHAP summary plots, partial dependence plots, and multi-tree visualizations to highlight variable importance.

---

## **Deliverables**

1. **R Scripts:** For API calls, cleaning, and modeling (XGBoost with Optuna).
2. **Processed Datasets:** Census tract-level crash data combined with socio-economic variables.
3. **EDA Outputs:** Borough-level crash trends, descriptive statistics, and heatmaps.
4. **Modeling Results:** Performance metrics (RMSE, MAE, R²) and residual diagnostics.
5. **Explainability Visuals:** SHAP global feature importance and interaction plots.
6. **Final Report:** Detailed findings, discussion of socio-economic predictors, and recommendations.

![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)
![Built with Quarto](https://img.shields.io/badge/docs-Quarto-orange)
