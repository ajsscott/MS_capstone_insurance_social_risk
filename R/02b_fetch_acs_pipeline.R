#!/usr/bin/env Rscript

# 02_fetch_acs.R
# Fetch ACS 5-Year data for NYC tracts (rolling 5 years) with extended variables.

required_packages <- c("tidycensus", "data.table", "sf", "lubridate", "aws.s3")
install_if_missing <- function(pkg) {
    if (!requireNamespace(pkg, quietly = TRUE)) install.packages(pkg)
}
invisible(lapply(required_packages, install_if_missing))

library(tidycensus)
library(data.table)
library(sf)
library(lubridate)
library(aws.s3)

# Load utilities
if (!file.exists("R/utils_api.R")) stop("utils_api.R not found in R/ directory.")
source("R/utils_api.R")

census_key <- Sys.getenv("CENSUS_API_KEY")
if (census_key == "") stop("CENSUS_API_KEY not set in .Renviron")
census_api_key(census_key, install = FALSE)

# Directories
local_dir <- "data/raw"
dir.create(local_dir, recursive = TRUE, showWarnings = FALSE)
local_file <- file.path(local_dir, "acs_latest.csv")
timestamped_file <- sprintf("%s/acs_%s.csv", local_dir, format(Sys.Date(), "%Y_%m_%d"))

# Use the helper to get all ACS variables
acs_vars <- build_acs_variables()

# Determine incremental fetch
last_year <- NULL
if (file.exists(local_file)) {
    message("Found local ACS data. Using max year for incremental update...")
    existing <- fread(local_file, select = "YEAR")
    last_year <- max(existing$YEAR, na.rm = TRUE)
}

date_range <- get_date_range(last_date = NULL, years_back = 5)
end_year <- lubridate::year(as.Date(date_range$end_date))
start_year <- end_year - 4
if (!is.null(last_year)) start_year <- last_year + 1

# Fetch data year by year
acs_dt_list <- list()
for (yr in start_year:end_year) {
    message(sprintf("Fetching ACS data for year %d...", yr))
    acs_data <- get_acs(
        geography = "tract",
        variables = acs_vars,
        year = yr,
        survey = "acs5",
        geometry = TRUE,
        state = "NY",
        county = c("New York", "Kings", "Queens", "Bronx", "Richmond")
    )
    dt <- as.data.table(acs_data)
    dt[, YEAR := yr]
    acs_dt_list[[as.character(yr)]] <- dt
}
new_data <- rbindlist(acs_dt_list, fill = TRUE)

# Merge and save
if (file.exists(local_file)) {
    old_dt <- fread(local_file)
    acs_dt <- rbindlist(list(old_dt, new_data), fill = TRUE)
} else {
    acs_dt <- new_data
}
fwrite(acs_dt, local_file)
fwrite(acs_dt, timestamped_file)
message(sprintf("ACS data saved to %s and %s", local_file, timestamped_file))

# Optional AWS S3 upload
bucket <- Sys.getenv("AWS_S3_BUCKET")
if (bucket != "") {
    message(sprintf("Uploading to S3 bucket: %s", bucket))
    put_object(file = timestamped_file, object = basename(timestamped_file), bucket = bucket)
    put_object(file = local_file, object = "acs_latest.csv", bucket = bucket)
}
