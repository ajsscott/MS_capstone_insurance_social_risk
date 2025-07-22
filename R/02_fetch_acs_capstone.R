#!/usr/bin/env Rscript
# 02_fetch_acs.R
# Fetch ACS socio-economic variables for NYC counties (2018–2023)
# Requires a valid Census API key stored in the CENSUS_API_KEY env variable

# ---------------------------
# 0. Package Setup
# ---------------------------
required_packages <- c("tidycensus", "dplyr", "purrr", "readr", "janitor")

install_if_missing <- function(pkg) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
        install.packages(pkg, repos = "https://cloud.r-project.org")
    }
}

invisible(lapply(required_packages, install_if_missing))

suppressPackageStartupMessages({
    library(tidycensus)
    library(dplyr)
    library(purrr)
    library(readr)
    library(janitor)
})

# ---------------------------
# 1. Census API Key
# ---------------------------
api_key <- Sys.getenv("CENSUS_API_KEY")
if (api_key == "") stop("No CENSUS_API_KEY found. Please set it in your .Renviron.")
census_api_key(api_key, install = FALSE, overwrite = TRUE)

# ---------------------------
# 2. ACS Table Setup
# ---------------------------
acs_tables <- c(
    # Core socio-economic indicators
    "B01001",  # Age and Sex
    "B01003",  # Total Population
    "B08134",  # Means of Transportation to Work by Vehicle Occupancy
    "B08301",  # Means of Transportation to Work
    "B08303",  # Travel Time to Work
    "B19001",  # Household Income Distribution
    "B19013",  # Median Household Income
    "B25010",  # Average Household Size
    "B25044",  # Tenure by Vehicles Available
    "C24010",  # Occupation by Sex and Median Earnings
    "C24030",  # Industry by Sex and Median Earnings
    "B15003",  # Educational Attainment
    "B17001",  # Poverty Status
    "B02001",  # Race
    "B03002",  # Hispanic or Latino Origin by Race
    "B08201",  # Household Size by Vehicles Available
    "B18101",  # Sex by Age by Disability Status
    "B16005",  # Nativity by Language Spoken at Home by English Proficiency
    "B23025",  # Employment Status for Population 16+
    "B25064",  # Median Gross Rent
    "B09005",  # Household Type (Families vs Non-families)
    "B11001"   # Household Type by Presence of Children
)

# NYC counties
nyc_counties <- c("Bronx", "Kings", "New York", "Queens", "Richmond")

# ---------------------------
# 3. Helper Functions
# ---------------------------

# Fetch one table for one year
fetch_table_year <- function(tbl, year) {
    message(sprintf("Fetching %s for %d...", tbl, year))
    
    tidycensus::get_acs(
        geography = "tract",
        table = tbl,
        state = "NY",
        county = nyc_counties,
        survey = "acs5",
        year = year,
        geometry = FALSE,  # Keep CSV light
        cache_table = TRUE
    ) %>%
        clean_names() %>%
        mutate(table_id = tbl, year = year)
}

# Fetch all tables for one year and combine
fetch_year_data <- function(year) {
    map_dfr(acs_tables, ~ fetch_table_year(.x, year))
}

# ---------------------------
# 4. Main Loop
# ---------------------------
years <- 2018:2023
output_dir <- "data/raw/acs"
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

walk(years, function(yr) {
    message(sprintf("Downloading ACS data for %d...", yr))
    
    acs_data <- fetch_year_data(yr)
    
    out_file <- file.path(output_dir, paste0("acs_", yr, ".csv"))
    readr::write_csv(acs_data, out_file)
    
    message(sprintf("Saved %s", out_file))
})

message("ACS download complete for 2018–2023.")
