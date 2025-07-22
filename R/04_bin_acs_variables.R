#!/usr/bin/env Rscript
# 04_bin_acs_variables.R
# Bins ACS variables with robust error handling

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
acs_path <- "data/raw/acs_2018_2023_raw.csv"
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
        return(rep(NA_real_, nrow(df)))
    }
    safe_sum(df, cols)
}

safe_mean <- function(df, col) {
    if (length(col) == 0 || !col %in% names(df)) {
        warning("Column not found: ", col)
        return(rep(NA_real_, nrow(df)))
    }
    df[[col]]
}

# ---------------------------
# 3. Binning with Error Handling
# ---------------------------

## --- Basic Demographics ---
acs <- acs %>% mutate(
    # Population totals
    total_population = safe_mean(., "estimate_total"),
    male_population = safe_mean(., "estimate_total_male"),
    female_population = safe_mean(., "estimate_total_female"),
    
    # Race/Ethnicity
    white_population = safe_mean(., "estimate_total_whitealone"),
    black_population = safe_mean(., "estimate_total_blackorafricanamericanalone"),
    asian_population = safe_mean(., "estimate_total_asianalone"),
    hispanic_population = safe_mean(., "estimate_total_hispanicorlatino"),
    foreign_born = safe_mean(., "estimate_total_foreignborn")
)

## --- Age Groups ---
acs <- acs %>% mutate(
    age_under_18 = safe_sum(., c(
        "estimate_total_male_under5years", "estimate_total_male_5to9years", 
        "estimate_total_male_10to14years", "estimate_total_male_15to17years",
        "estimate_total_female_under5years", "estimate_total_female_5to9years",
        "estimate_total_female_10to14years", "estimate_total_female_15to17years"
    )),
    age_18_34 = safe_sum(., c(
        "estimate_total_male_18to34years", "estimate_total_female_18to34years"
    )),
    age_35_64 = safe_sum(., c(
        "estimate_total_male_35to64years", "estimate_total_female_35to64years"
    )),
    age_65_plus = safe_sum(., c(
        "estimate_total_male_65to74years", "estimate_total_male_75yearsandover",
        "estimate_total_female_65to74years", "estimate_total_female_75yearsandover"
    ))
)

## --- Income ---
acs <- acs %>% mutate(
    median_income = safe_mean(., "estimate_medianhouseholdincomeinthepast12months(in2018inflation-adjusteddollars)"),
    income_under_25k = safe_sum(., c(
        "estimate_total_lessthan10_000", "estimate_total_10_000to14_999",
        "estimate_total_15_000to19_999", "estimate_total_20_000to24_999"
    )),
    income_25k_75k = safe_sum(., c(
        "estimate_total_25_000to29_999", "estimate_total_30_000to34_999",
        "estimate_total_35_000to39_999", "estimate_total_40_000to44_999",
        "estimate_total_45_000to49_999", "estimate_total_50_000to59_999",
        "estimate_total_60_000to74_999"
    )),
    income_75k_plus = safe_sum(., c(
        "estimate_total_75_000to99_999", "estimate_total_100_000to124_999",
        "estimate_total_125_000to149_999", "estimate_total_150_000to199_999",
        "estimate_total_200_000ormore"
    ))
)

## --- Poverty ---
acs <- acs %>% mutate(
    below_poverty = safe_mean(., "estimate_total_incomeinthepast12monthsbelowpovertylevel"),
    above_poverty = safe_mean(., "estimate_total_incomeinthepast12monthsatorabovepovertylevel"),
    poverty_rate = ifelse((below_poverty + above_poverty) > 0,
                          below_poverty / (below_poverty + above_poverty) * 100,
                          NA_real_)
)

## --- Housing ---
acs <- acs %>% mutate(
    median_gross_rent = safe_mean(., "estimate_mediangrossrent"),
    owner_occupied = safe_mean(., "estimate_total_owneroccupied"),
    renter_occupied = safe_mean(., "estimate_total_renteroccupied")
)

## --- Vehicles ---
acs <- acs %>% mutate(
    no_vehicle = safe_mean(., "estimate_total_novehicleavailable"),
    one_vehicle = safe_mean(., "estimate_total_1vehicleavailable"),
    two_plus_vehicles = safe_sum(., c(
        "estimate_total_2vehiclesavailable", "estimate_total_3vehiclesavailable",
        "estimate_total_4ormorevehiclesavailable"
    ))
)

## --- Education ---
acs <- acs %>% mutate(
    less_than_hs = safe_sum(., c(
        "estimate_total_noschoolingcompleted", "estimate_total_nurseryschool",
        "estimate_total_kindergarten", "estimate_total_1stgrade",
        "estimate_total_2ndgrade", "estimate_total_3rdgrade",
        "estimate_total_4thgrade", "estimate_total_5thgrade",
        "estimate_total_6thgrade", "estimate_total_7thgrade",
        "estimate_total_8thgrade", "estimate_total_9thgrade",
        "estimate_total_10thgrade", "estimate_total_11thgrade",
        "estimate_total_12thgrade_nodiploma"
    )),
    hs_diploma = safe_mean(., "estimate_total_regularhighschooldiploma"),
    some_college = safe_sum(., c(
        "estimate_total_somecollege_lessthan1year",
        "estimate_total_somecollege_1ormoreyears_nodegree"
    )),
    associates_degree = safe_mean(., "estimate_total_associatesdegree"),
    bachelors_degree = safe_mean(., "estimate_total_bachelorsdegree"),
    graduate_degree = safe_sum(., c(
        "estimate_total_mastersdegree", "estimate_total_professionalschooldegree",
        "estimate_total_doctoratedegree"
    ))
)

## --- Employment ---
acs <- acs %>% mutate(
    in_labor_force = safe_mean(., "estimate_total_inlaborforce"),
    employed = safe_mean(., "estimate_total_inlaborforce_civilianlaborforce_employed"),
    unemployed = safe_mean(., "estimate_total_inlaborforce_civilianlaborforce_unemployed"),
    not_in_labor_force = safe_mean(., "estimate_total_notinlaborforce"),
    unemployment_rate = ifelse(in_labor_force > 0,
                               unemployed / in_labor_force * 100,
                               NA_real_)
)

## --- Commute ---
acs <- acs %>% mutate(
    commute_short = safe_sum(., c(
        "estimate_total_lessthan5minutes", "estimate_total_lessthan10minutes",
        "estimate_total_5to9minutes", "estimate_total_10to14minutes"
    )),
    commute_medium = safe_sum(., c(
        "estimate_total_15to19minutes", "estimate_total_20to24minutes",
        "estimate_total_25to29minutes"
    )),
    commute_long = safe_sum(., c(
        "estimate_total_30to34minutes", "estimate_total_35to39minutes",
        "estimate_total_40to44minutes", "estimate_total_45to59minutes",
        "estimate_total_60ormoreminutes"
    ))
)

## --- Transportation Mode ---
acs <- acs %>% mutate(
    drive_alone = safe_mean(., "estimate_total_car_truck_orvan_drovealone"),
    carpool = safe_mean(., "estimate_total_car_truck_orvan_carpooled"),
    public_transit = safe_mean(., "estimate_total_publictransportation(excludingtaxicab)"),
    walk = safe_mean(., "estimate_total_walked"),
    bike = safe_mean(., "estimate_total_bicycle"),
    work_from_home = safe_mean(., "estimate_total_workedathome")
)

# ---------------------------
# 4. Convert Counts to Percentages
# ---------------------------

# List of count variables to convert to percentages
count_vars <- c(
    "male_population", "female_population",
    "white_population", "black_population", "asian_population", 
    "hispanic_population", "foreign_born",
    "age_under_18", "age_18_34", "age_35_64", "age_65_plus",
    "income_under_25k", "income_25k_75k", "income_75k_plus",
    "below_poverty", "above_poverty",
    "owner_occupied", "renter_occupied",
    "no_vehicle", "one_vehicle", "two_plus_vehicles",
    "less_than_hs", "hs_diploma", "some_college", 
    "associates_degree", "bachelors_degree", "graduate_degree",
    "in_labor_force", "employed", "unemployed", "not_in_labor_force",
    "commute_short", "commute_medium", "commute_long",
    "drive_alone", "carpool", "public_transit", "walk", "bike", "work_from_home"
)

# Convert all count variables to percentages
acs <- acs %>% 
    mutate(across(all_of(count_vars), 
                  ~ ifelse(total_population > 0, (.x / total_population) * 100, NA_real_),
                  .names = "pct_{.col}")) %>%
    select(-all_of(count_vars))  # Remove the original count columns


# ---------------------------
# 5. Select Final Variables
# ---------------------------
acs <- acs %>% select(
    geoid, year, total_population,
    # Demographics
    pct_male_population, pct_female_population,
    pct_white_population, pct_black_population, pct_asian_population, 
    pct_hispanic_population, pct_foreign_born,
    # Age
    pct_age_under_18, pct_age_18_34, pct_age_35_64, pct_age_65_plus,
    # Income
    median_income, pct_income_under_25k, pct_income_25k_75k, pct_income_75k_plus,
    # Poverty
    pct_below_poverty, pct_above_poverty, poverty_rate,
    # Housing
    median_gross_rent, pct_owner_occupied, pct_renter_occupied,
    # Vehicles
    pct_no_vehicle, pct_one_vehicle, pct_two_plus_vehicles,
    # Education
    pct_less_than_hs, pct_hs_diploma, pct_some_college, pct_associates_degree,
    pct_bachelors_degree, pct_graduate_degree,
    # Employment
    pct_in_labor_force, pct_employed, pct_unemployed, pct_not_in_labor_force, unemployment_rate,
    # Commute
    pct_commute_short, pct_commute_medium, pct_commute_long,
    # Transportation
    pct_drive_alone, pct_carpool, pct_public_transit, pct_walk, pct_bike, pct_work_from_home
)

# ---------------------------
# 6. Save Output
# ---------------------------
output_path <- "data/processed/acs_2018_2023_pct.csv"
write_csv(acs, output_path)

message("Binned ACS dataset with percentages saved to: ", output_path)