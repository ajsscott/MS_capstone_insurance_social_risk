
# Outline: Auto Insurance Risk Prediction Using Gradient Boosting

## Title
Auto Insurance Risk Prediction: Identifying Socio-Economic Drivers of Claim Frequency and Severity with Gradient Boosting Models

## Abstract
- Introduce the importance of predictive modeling for auto insurance risk.
- Highlight the integration of **NYC crash data and ACS socio-economic data** via APIs.
- Summarize the use of **gradient boosting models and SHAP explainability**.
- Note the inclusion of **advanced geospatial and interactive visualizations** for insights.

## 1. Introduction
- Background on auto insurance risk assessment and the limitations of traditional actuarial models.
- Growing role of machine learning and explainable AI in insurance analytics.
- Objectives and research question: identifying socio-economic and transportation factors influencing claim frequency/severity.

## 2. Related Work
- Review of ML applications in insurance risk modeling.
- Studies involving crash data, socio-economic features, and geospatial analytics.
- Explainability techniques (e.g., SHAP) in predictive modeling.

## 3. Materials and Methods
### 3.1 Data Sources
- NYC Open Data Motor Vehicle Collisions (via API).
- ACS 5-Year socio-economic indicators (via U.S. Census Bureau API).
### 3.2 Key Metrics
- Claim frequency proxy: crashes per 1,000 residents.
- Claim severity proxy: injury/fatality ratios.
### 3.3 Modeling Approach
- Gradient boosting (XGBoost/LightGBM).
- Hyperparameter optimization (Optuna).
### 3.4 Explainability
- SHAP-based global and local feature analysis.

## 4. Results
- Model performance metrics (AUC, RMSE).
- Feature importance rankings (SHAP).
- Visual findings (maps, animations, dashboards).

## 5. Conclusions and Future Work
- Key insights and implications for insurance risk modeling.
- Limitations and suggested extensions (e.g., telematics, temporal models).
- Potential improvements in visualization and explainability.
