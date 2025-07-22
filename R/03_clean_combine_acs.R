#!/usr/bin/env Rscript
# 03_clean_combine_acs.R
# Combine and clean yearly ACS CSV files (2018–2023), detecting when 2020 tracts are already in 2020 boundaries.
# Outputs:
#   - data/processed/acs_2018_2023_wide.csv
#   - data/processed/acs_variable_dictionary.csv

# ---------------------------
# 0. Package Setup
# ---------------------------
required_packages <- c("dplyr", "readr", "tidyr", "stringr", "purrr", "janitor", "tidycensus")

install_if_missing <- function(pkg) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
        install.packages(pkg, repos = "https://cloud.r-project.org")
    }
}
invisible(lapply(required_packages, install_if_missing))

suppressPackageStartupMessages({
    library(dplyr)
    library(readr)
    library(tidyr)
    library(stringr)
    library(purrr)
    library(janitor)
    library(tidycensus)
})

# ---------------------------
# 1. File Paths
# ---------------------------
acs_dir <- "data/raw/acs"
output_dir <- "data/raw"
crosswalk_path <- "data/processed/census_tract_relationships.csv"

if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

# ---------------------------
# 2. Helper Functions
# ---------------------------
clean_acs_data <- function(df) {
    df %>%
        clean_names() %>%
        mutate(
            geoid = str_pad(as.character(geoid), width = 11, pad = "0"),
            variable = str_to_lower(variable),
            table_id = str_to_lower(table_id),
            year = as.integer(year)
        )
}

generate_variable_dict <- function(years, tables) {
    vars_list <- map(years, ~ {
        tidycensus::load_variables(.x, "acs5", cache = TRUE) %>%
            mutate(year = .x)
    })
    all_vars <- bind_rows(vars_list)
    all_vars %>%
        filter(str_to_upper(substr(name, 1, 6)) %in% toupper(tables)) %>%
        distinct(name, label) %>%
        group_by(name) %>%
        slice(1) %>%
        ungroup() %>%
        mutate(
            variable = str_to_lower(name),
            description = str_to_lower(gsub("!!", "_", label))
        ) %>%
        select(variable, description)
}

apply_variable_labels <- function(df, dict) {
    df %>%
        left_join(dict, by = "variable") %>%
        mutate(var_label = if_else(!is.na(description), description, variable))
}

# ---------------------------
# 3. Read & Combine Yearly Files
# ---------------------------
acs_files <- list.files(acs_dir, pattern = "^acs_\\d{4}\\.csv$", full.names = TRUE)

acs_list <- map(acs_files, ~ {
    read_csv(.x, show_col_types = FALSE) %>%
        clean_acs_data()
})

acs_long <- bind_rows(acs_list)

message("ACS data loaded with ", nrow(acs_long), " rows and ", length(unique(acs_long$geoid)), " unique GEOIDs.")
message("Years present: ", paste(unique(acs_long$year), collapse = ", "))

tables_in_data <- unique(acs_long$table_id)
years <- unique(acs_long$year)

variable_dict <- generate_variable_dict(years, tables_in_data)
acs_long <- apply_variable_labels(acs_long, variable_dict)

# Identify var_label for total population
total_pop_var <- variable_dict %>%
    filter(variable == "b01003_001") %>%
    pull(description)
if (length(total_pop_var) == 0) total_pop_var <- "b01003_001"

# ---------------------------
# 4. Load Crosswalk
# ---------------------------
crosswalk <- read_csv(
    crosswalk_path,
    col_types = cols(
        GEOID_TRACT_20 = col_character(),
        GEOID_TRACT_10 = col_character(),
        AREALAND_TRACT_10 = col_double(),
        AREALAND_PART = col_double()
    )
) %>%
    rename(
        tract_2020 = GEOID_TRACT_20,
        tract_2010 = GEOID_TRACT_10,
        area_part = AREALAND_PART,
        area_2010 = AREALAND_TRACT_10
    ) %>%
    mutate(weight = if_else(area_2010 > 0, area_part / area_2010, 0)) %>%
    select(tract_2010, tract_2020, weight)

message("Crosswalk loaded: ", nrow(crosswalk), " rows")
print(head(crosswalk, 5))

# ---------------------------
# 5. Split ACS Data
# ---------------------------
acs_2018_2019 <- acs_long %>% filter(year <= 2019)
acs_2020_2023 <- acs_long %>% filter(year >= 2020)

# Check 2020 GEOIDs against crosswalk
unmatched_2020 <- acs_2020_2023 %>%
    filter(year == 2020) %>%
    anti_join(crosswalk, by = c("geoid" = "tract_2010")) %>%
    distinct(geoid)

if (nrow(unmatched_2020) > 0) {
    message("2020 ACS GEOIDs appear to be 2020 tracts. Crosswalk will only be applied to 2018–2019.")
} else {
    message("2020 ACS GEOIDs match 2010 tracts. Crosswalk will be applied to 2018–2020.")
    acs_2018_2019 <- acs_long %>% filter(year <= 2020)
    acs_2020_2023 <- acs_long %>% filter(year >= 2021)
}

# ---------------------------
# 6. Apply Crosswalk to 2018–2019
# ---------------------------
if (nrow(acs_2018_2019) > 0) {
    pop_before <- acs_2018_2019 %>%
        filter(var_label == total_pop_var) %>%
        group_by(year) %>%
        summarise(total_pop = sum(estimate, na.rm = TRUE), .groups = "drop")
    message("Population totals before crosswalk:")
    print(pop_before)
    
    acs_2018_2019 <- acs_2018_2019 %>%
        left_join(crosswalk, by = c("geoid" = "tract_2010"), relationship = "many-to-many") %>%
        mutate(weighted_estimate = estimate * weight) %>%
        group_by(tract_2020, year, var_label) %>%
        summarise(estimate = sum(weighted_estimate, na.rm = TRUE), .groups = "drop") %>%
        rename(geoid = tract_2020)
    
    pop_after <- acs_2018_2019 %>%
        filter(var_label == total_pop_var) %>%
        group_by(year) %>%
        summarise(total_pop = sum(estimate, na.rm = TRUE), .groups = "drop")
    message("Population totals after crosswalk:")
    print(pop_after)
}

# ---------------------------
# 7. Combine Data
# ---------------------------
acs_long <- bind_rows(acs_2018_2019, acs_2020_2023)

acs_long <- acs_long %>%
    group_by(geoid, year, var_label) %>%
    summarise(estimate = sum(estimate, na.rm = TRUE), .groups = "drop")

# ---------------------------
# 8. Pivot to Wide Format
# ---------------------------
acs_wide <- acs_long %>%
    pivot_wider(
        names_from = var_label,
        values_from = estimate
    )

# ---------------------------
# 9. Normalize Column Names
# ---------------------------
acs_wide <- acs_wide %>%
    rename_with(~ gsub("[ $']", "", .x)) %>%  # remove spaces, $, and '
    rename_with(~ gsub(" ", "_", .x)) %>%     # replace spaces with underscores
    rename_with(~ gsub(",", "_", .x)) %>%
    rename_with(~ gsub("\\s+", "_", .x)) %>%  # handle multiple spaces
    rename_with(~ tolower(.x)) 

# ---------------------------
# 10. Save Outputs
# ---------------------------
write_csv(acs_wide, file.path(output_dir, "acs_2018_2023_raw.csv"))
write_csv(variable_dict, file.path(output_dir, "acs_variable_dictionary.csv"))

message("ACS data normalized (2018–2019 only) and saved: acs_2018_2023_raw.csv and acs_variable_dictionary.csv om /data/raw/")
