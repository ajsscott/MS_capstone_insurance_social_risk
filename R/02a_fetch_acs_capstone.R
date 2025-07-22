#!/usr/bin/env Rscript

# 02_fetch_acs.R
# Fetch ACS 5-Year data for NYC tracts (2018-2022) using tidycensus

library(tidycensus)
library(data.table)
library(sf)

# Load utils
source("R/utils_api.R")

# Set Census API key (ensure it's set in environment)
api_key <- Sys.getenv("CENSUS_API_KEY")
if (api_key == "") stop("CENSUS_API_KEY not set in environment.")

census_api_key(api_key, install = FALSE)

# Variables to pull
acs_vars <- c(
    median_income = "B19013_001",
    vehicle_availability = "B25044_003",
    commute_car = "B08301_002",
    commute_subway = "B08301_010",
    commute_walk = "B08301_018"
)

# Fetch ACS
message("Fetching ACS data...")
acs_data <- get_acs(
    geography = "tract",
    variables = acs_vars,
    year = 2022,
    survey = "acs5",
    geometry = TRUE,
    state = "NY",
    county = c("New York", "Kings", "Queens", "Bronx", "Richmond")
)

# Convert to data.table
acs_dt <- as.data.table(acs_data)

# Save
dir.create("data/raw", showWarnings = FALSE, recursive = TRUE)
timestamp <- format(Sys.Date(), "%Y_%m_%d")
out_file <- sprintf("data/raw/acs_%s.csv", timestamp)
fwrite(acs_dt, out_file)

message(sprintf("ACS data saved to %s", out_file))
