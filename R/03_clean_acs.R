#!/usr/bin/env Rscript
# 03_clean_combine_acs.R
# Combine and clean yearly ACS CSV files (2018–2023) with deduplication and an auto-generated variable dictionary.
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
output_dir <- "data/processed"
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

# ---------------------------
# 2. Helper Functions
# ---------------------------
clean_acs_data <- function(df) {
    df %>%
        clean_names() %>%
        mutate(
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

# Identify tables and years
tables_in_data <- unique(acs_long$table_id)
years <- unique(acs_long$year)

# Generate variable dictionary
variable_dict <- generate_variable_dict(years, tables_in_data)

# Apply variable labels
acs_long <- apply_variable_labels(acs_long, variable_dict)

# ---------------------------
# 4. Deduplicate & Summarize
# ---------------------------
acs_long <- acs_long %>%
    group_by(geoid, name, year, var_label) %>%
    summarise(estimate = sum(estimate, na.rm = TRUE), .groups = "drop")

# ---------------------------
# 5. Pivot to Wide Format (All Years)
# ---------------------------
acs_wide <- acs_long %>%
    pivot_wider(
        names_from = var_label,
        values_from = estimate
    )

# ---------------------------
# 6. Save Final Outputs
# ---------------------------
write_csv(acs_wide, file.path(output_dir, "acs_2018_2023_wide.csv"))
write_csv(variable_dict, file.path(output_dir, "acs_variable_dictionary.csv"))

message("ACS files cleaned and saved: acs_2018_2023_wide.csv and acs_variable_dictionary.csv")
