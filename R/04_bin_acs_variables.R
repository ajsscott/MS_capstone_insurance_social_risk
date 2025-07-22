#!/usr/bin/env Rscript
# 04_bin_acs_variables.R
# Bins ACS variables with robust error handling and race-stratified aggregation

# ---------------------------
# 0. Package Setup
# ---------------------------
required_packages <- c("dplyr", "readr", "stringr", "purrr")

install_if_missing <- function(pkg) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
        install.packages(pkg, repos = "https://cloud.r-project.org")
    }
}

invisible(lapply(required_packages, install_if_missing))

suppressPackageStartupMessages({
    library(dplyr)
    library(readr)
    library(stringr)
    library(purrr)
})

# ---------------------------
# 1. Load Data
# ---------------------------
acs_path <- "data/processed/acs_2018_2023_wide.csv"
acs <- read_csv(acs_path, show_col_types = FALSE)

# ---------------------------
# 2. Helper Functions
# ---------------------------
safe_sum <- function(df, cols) {
    if (length(cols) == 0) return(rep(0, nrow(df)))
    rowSums(select(df, all_of(cols)), na.rm = TRUE)
}

safe_agg <- function(df, pattern) {
    cols <- grep(pattern, names(df), value = TRUE)
    if (length(cols) == 0) {
        warning("No columns found for pattern: ", pattern)
        return(rep(NA_real_, nrow(df))))
    }
    safe_sum(df, cols)
}

# ---------------------------
# 3. Binning with Error Handling
# ---------------------------

## --- Age ---
age_vars <- list(
    under_18 = "^b01001[a-i]_(00[3-6]|00[18-9]|010|026|027|028|029|030)$",
    18_34 = "^b01001[a-i]_(0(0[7-9]|1[0-2])$",
    35_64 = "^b01001[a-i]_(0(1[3-5])$",
    65_plus = "^b01001[a-i]_(0(1[6-9]|2[0-5])$"
)

acs <- acs %>% mutate(
    pop_under_18 = safe_agg(., age_vars$under_18),
    pop_18_34 = safe_agg(., age_vars$18_34),
    pop_35_64 = safe_agg(., age_vars$35_64),
    pop_65_plus = safe_agg(., age_vars$65_plus)
)

## --- Income ---
income_vars <- list(
    low = "^b19001[a-i]_(00[2-5])$",
    mid = "^b19001[a-i]_(00[6-9]|010|011)$",
    high = "^b19001[a-i]_(012|013|014|015|016|017)$"
)

acs <- acs %>% mutate(
    hh_income_low = safe_agg(., income_vars$low),
    hh_income_mid = safe_agg(., income_vars$mid),
    hh_income_high = safe_agg(., income_vars$high)
)

## --- Poverty (B17001) ---
# Race-stratified aggregation
poverty_below <- grep("^b17001[a-i]_(00[2-9]|01[0-5])$", names(acs), value = TRUE)
poverty_total <- grep("^b17001[a-i]_001$", names(acs), value = TRUE)

if (length(poverty_total) > 0 && length(poverty_below) > 0) {
    acs <- acs %>% mutate(
        pop_below_poverty = safe_sum(., poverty_below),
        pop_above_poverty = safe_sum(., poverty_total) - pop_below_poverty,
        pct_below_poverty = if_else(safe_sum(., poverty_total) > 0,
                                    pop_below_poverty / safe_sum(., poverty_total) * 100, 
                                    NA_real_)
    )
} else {
    warning("Poverty columns (B17001) not found. Skipping poverty calculations.")
    acs <- acs %>% mutate(
        pop_below_poverty = NA_real_,
        pop_above_poverty = NA_real_,
        pct_below_poverty = NA_real_
    )
}

## --- Employment (B23025) ---
employed_cols <- grep("^b23025_004$", names(acs), value = TRUE)
unemployed_cols <- grep("^b23025_005$", names(acs), value = TRUE)
labor_force_cols <- grep("^b23025_003$", names(acs), value = TRUE)
population_16plus_cols <- grep("^b23025_002$", names(acs), value = TRUE)

if (length(employed_cols) > 0 && length(unemployed_cols) > 0 && 
    length(labor_force_cols) > 0 && length(population_16plus_cols) > 0) {
    acs <- acs %>% mutate(
        employed = .[[employed_cols]],
        unemployed = .[[unemployed_cols]],
        not_in_labor_force = .[[population_16plus_cols]] - .[[labor_force_cols]],
        labor_force_participation = if_else(.[[population_16plus_cols]] > 0,
                                            .[[labor_force_cols]] / .[[population_16plus_cols]] * 100, 
                                            NA_real_)
    )
} else {
    warning("Employment columns (B23025) not found. Skipping employment calculations.")
    acs <- acs %>% mutate(
        employed = NA_real_,
        unemployed = NA_real_,
        not_in_labor_force = NA_real_,
        labor_force_participation = NA_real_
    )
}

## --- Commute Time ---
commute_vars <- list(
    short = "^b08303_00[2-3]$",
    medium = "^b08303_00[4-6]$",
    long = "^b08303_00[7-9]|010$"
)

acs <- acs %>% mutate(
    commute_short = safe_agg(., commute_vars$short),
    commute_medium = safe_agg(., commute_vars$medium),
    commute_long = safe_agg(., commute_vars$long)
)

## --- Transportation Mode ---
transport_vars <- list(
    drive = "^b08134_00[2-3]$",
    transit = "^b08301_0(10|11|12|13)$",
    walk_bike = "^b08301_0(18|19)$"
)

acs <- acs %>% mutate(
    pct_drive = safe_agg(., transport_vars$drive),
    pct_transit = safe_agg(., transport_vars$transit),
    pct_walk_bike = safe_agg(., transport_vars$walk_bike)
)

## --- Education ---
edu_vars <- list(
    no_hs = "^b15003_00[2-9]|010$",
    hs = "^b15003_011$",
    some_college = "^b15003_01[2-4]$",
    bachelor_plus = "^b15003_01[5-9]|02[0-5]$"
)

acs <- acs %>% mutate(
    edu_no_highschool = safe_agg(., edu_vars$no_hs),
    edu_highschool = safe_agg(., edu_vars$hs),
    edu_some_college = safe_agg(., edu_vars$some_college),
    edu_bachelor_plus = safe_agg(., edu_vars$bachelor_plus)
)

## --- Vehicles ---
vehicle_vars <- list(
    none = "^b25044_00(3|10)$",
    one = "^b25044_00(4|11)$",
    two_plus = "^b25044_00(5|6|12|13)$"
)

acs <- acs %>% mutate(
    hh_no_vehicle = safe_agg(., vehicle_vars$none),
    hh_1_vehicle = safe_agg(., vehicle_vars$one),
    hh_2plus_vehicle = safe_agg(., vehicle_vars$two_plus)
)

## --- Occupation (C24010) ---
occ_vars <- list(
    management = "^c24010[a-i]_00[2-5]$",
    service = "^c24010[a-i]_00[6-7]$",
    sales_office = "^c24010[a-i]_00[8-9]$",
    natural_construction = "^c24010[a-i]_010$",
    production_transport = "^c24010[a-i]_01[1-2]$"
)

acs <- acs %>% mutate(
    occ_management_professional = safe_agg(., occ_vars$management),
    occ_service = safe_agg(., occ_vars$service),
    occ_sales_office = safe_agg(., occ_vars$sales_office),
    occ_natural_construction = safe_agg(., occ_vars$natural_construction),
    occ_production_transport = safe_agg(., occ_vars$production_transport)
)

## --- Industry (C24030) ---
ind_vars <- list(
    agriculture_mining = "^c24030[a-i]_00[2-3]$",
    construction_manufacturing = "^c24030[a-i]_00[4-5]$",
    wholesale_retail = "^c24030[a-i]_00[6-7]$",
    finance_professional = "^c24030[a-i]_00[8-9]|010|011$",
    education_health = "^c24030[a-i]_01[2-3]$",
    arts_recreation = "^c24030[a-i]_014$",
    other = "^c24030[a-i]_01[5-8]$"
)

acs <- acs %>% mutate(
    ind_agriculture_mining = safe_agg(., ind_vars$agriculture_mining),
    ind_construction_manufacturing = safe_agg(., ind_vars$construction_manufacturing),
    ind_wholesale_retail = safe_agg(., ind_vars$wholesale_retail),
    ind_finance_professional = safe_agg(., ind_vars$finance_professional),
    ind_education_health = safe_agg(., ind_vars$education_health),
    ind_arts_recreation = safe_agg(., ind_vars$arts_recreation),
    ind_other_industries = safe_agg(., ind_vars$other)
)

# ---------------------------
# 4. Drop Original Columns
# ---------------------------
# Create list of all original columns we tried to use
all_original_cols <- c(
    unlist(age_vars), unlist(income_vars), poverty_below, poverty_total,
    employed_cols, unemployed_cols, labor_force_cols, population_16plus_cols,
    unlist(commute_vars), unlist(transport_vars), unlist(edu_vars),
    unlist(vehicle_vars), unlist(occ_vars), unlist(ind_vars)
)

# Get actual column names that exist in the data
existing_cols <- unique(grep(paste(all_original_cols, collapse = "|"), 
                             names(acs), value = TRUE))

# Remove original columns if they exist
if (length(existing_cols) > 0) {
    acs <- acs %>% select(-any_of(existing_cols))
}

# ---------------------------
# 5. Save Output
# ---------------------------
output_path <- "data/processed/acs_2018_2023_binned.csv"
write_csv(acs, output_path)

message("Binned ACS dataset saved to: ", output_path)