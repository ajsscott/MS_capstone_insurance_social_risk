#!/usr/bin/env Rscript

# 05_clean_mvc.R
# Aggregate NYC Motor Vehicle Collisions (MVC) data by 2020 Census Tract GEOID.
# Outputs: crash counts, injury counts, fatality counts, and rates per 1,000 residents by year.

# ---------------------------
# 0. Setup
# ---------------------------
required_packages <- c("data.table", "sf", "dplyr", "stringr", "lubridate", "readr")

install_if_missing <- function(pkg) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
        install.packages(pkg, repos = "https://cloud.r-project.org")
    }
}
invisible(lapply(required_packages, install_if_missing))

suppressPackageStartupMessages({
    library(data.table)
    library(sf)
    library(dplyr)
    library(stringr)
    library(lubridate)
    library(readr)
})

# ---------------------------
# 1. File Paths
# ---------------------------
mvc_file <- "data/raw/mvc_2025_07_22.csv"       # Collision data (from NYC Open Data)
acs_file <- "data/processed/acs_2018_2023_pct.csv" # ACS dataset with population by tract/year
nta_shapefile <- "data/shapefiles/tl_2020_36_tract.shp" # 2020 census tract boundaries

output_dir <- "data/processed"
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

# ---------------------------
# 2. Load Data with Error Checks
# ---------------------------
message("\nLoading data files...")

# Check if files exist before loading
if (!file.exists(mvc_file)) {
    stop("MVC data file not found: ", mvc_file)
}
if (!file.exists(acs_file)) {
    stop("ACS data file not found: ", acs_file)
}
if (!file.exists(nta_shapefile)) {
    stop("Shapefile not found: ", nta_shapefile)
}

# Load data with tryCatch for better error handling
tryCatch({
    mvc <- fread(mvc_file)
    message("MVC data loaded successfully with ", nrow(mvc), " rows.")
    
    acs <- fread(acs_file)
    message("ACS data loaded successfully with ", nrow(acs), " rows.")
    
    # Check required columns in MVC data
    required_mvc_cols <- c("crash_date", "longitude", "latitude", 
                           "number_of_persons_injured", "number_of_persons_killed",
                           "number_of_pedestrians_injured", "number_of_pedestrians_killed",
                           "number_of_cyclist_injured", "number_of_cyclist_killed",
                           "number_of_motorist_injured", "number_of_motorist_killed")
    
    missing_cols <- setdiff(required_mvc_cols, names(mvc))
    if (length(missing_cols) > 0) {
        stop("Missing required columns in MVC data: ", paste(missing_cols, collapse = ", "))
    }
    
    # Process year column
    mvc <- mvc %>%
        mutate(
            crash_date = ymd_hms(crash_date, quiet = TRUE),
            year = year(crash_date)
        ) %>%
        filter(!is.na(year))
    
    message("Years extracted from crash dates. Available years: ", paste(sort(unique(mvc$year)), collapse = ", "))
    
}, error = function(e) {
    stop("Error loading data: ", e$message)
})

# ---------------------------
# 3. Remove Invalid Coordinates
# ---------------------------
message("\nCleaning coordinate data...")

n_missing_coords <- sum(is.na(mvc$longitude) | is.na(mvc$latitude))
n_zero_coords <- sum(mvc$longitude == 0 & mvc$latitude == 0, na.rm = TRUE)

message("Rows with missing coordinates removed: ", n_missing_coords)
message("Rows with (0,0) coordinates removed: ", n_zero_coords)

mvc_clean <- mvc %>%
    filter(
        !is.na(longitude),
        !is.na(latitude),
        longitude != 0,
        latitude != 0
    )

message("Remaining rows after coordinate cleaning: ", nrow(mvc_clean))

# ---------------------------
# 4. Load 2020 Census Tract Boundaries
# ---------------------------
message("\nLoading and processing shapefile...")

tryCatch({
    tracts <- st_read(nta_shapefile, quiet = TRUE) %>%
        st_make_valid() %>%
        st_transform(4326)
    
    message("Shapefile loaded successfully with ", nrow(tracts), " features.")
    message("CRS: ", st_crs(tracts)$input)
    
    # Check for required GEOID column
    if (!"GEOID" %in% names(tracts)) {
        stop("Shapefile is missing required GEOID column")
    }
}, error = function(e) {
    stop("Error processing shapefile: ", e$message)
})

# ---------------------------
# 5. Convert MVC Data to sf and Spatial Join
# ---------------------------
message("\nPerforming spatial join...")

tryCatch({
    mvc_sf <- st_as_sf(
        mvc_clean,
        coords = c("longitude", "latitude"),
        crs = 4326,
        remove = FALSE
    )
    
    message("MVC data converted to sf object successfully.")
    
    mvc_joined <- st_join(mvc_sf, tracts, join = st_within)
    
    n_missing_geoid <- sum(is.na(mvc_joined$GEOID))
    message("Rows that didn't join to any tract (removed): ", n_missing_geoid)
    
    mvc_joined <- mvc_joined %>%
        filter(!is.na(GEOID))
    
    message("Final joined dataset has ", nrow(mvc_joined), " rows.")
}, error = function(e) {
    stop("Error in spatial operations: ", e$message)
})

# ---------------------------
# 6. Aggregate by GEOID and Year
# ---------------------------
message("\nAggregating data by GEOID and year...")

tryCatch({
    mvc_summary <- mvc_joined %>%
        st_drop_geometry() %>%
        group_by(GEOID, year) %>%
        summarise(
            total_crashes = n(),
            persons_injured = sum(as.numeric(number_of_persons_injured), na.rm = TRUE),
            persons_killed = sum(as.numeric(number_of_persons_killed), na.rm = TRUE),
            pedestrians_injured = sum(as.numeric(number_of_pedestrians_injured), na.rm = TRUE),
            pedestrians_killed = sum(as.numeric(number_of_pedestrians_killed), na.rm = TRUE),
            cyclists_injured = sum(as.numeric(number_of_cyclist_injured), na.rm = TRUE),
            cyclists_killed = sum(as.numeric(number_of_cyclist_killed), na.rm = TRUE),
            motorists_injured = sum(as.numeric(number_of_motorist_injured), na.rm = TRUE),
            motorists_killed = sum(as.numeric(number_of_motorist_killed), na.rm = TRUE),
            .groups = "drop"
        )
    
    message("Aggregation complete. Result has ", nrow(mvc_summary), " rows.")
}, error = function(e) {
    stop("Error in aggregation: ", e$message)
})

# ---------------------------
# 7. Merge ACS Population and Calculate Rates
# ---------------------------
message("\nMerging with ACS population data...")

tryCatch({
    # Prepare ACS data
    acs_pop <- acs %>%
        mutate(geoid = as.character(geoid)) %>%
        select(geoid, year, total_population)
    
    # Check for missing population data
    missing_pop_years <- setdiff(unique(mvc_summary$year), unique(acs_pop$year))
    if (length(missing_pop_years) > 0) {
        warning("ACS data is missing population for years: ", paste(missing_pop_years, collapse = ", "))
    }
    
    # Merge and calculate rates
    mvc_final <- mvc_summary %>%
        mutate(GEOID = as.character(GEOID)) %>%
        left_join(acs_pop, by = c("GEOID" = "geoid", "year" = "year")) %>%
        mutate(
            crash_rate_per_1000 = ifelse(total_population > 0, (total_crashes / total_population) * 1000, NA),
            injury_rate_per_1000 = ifelse(total_population > 0, (persons_injured / total_population) * 1000, NA),
            fatality_rate_per_1000 = ifelse(total_population > 0, (persons_killed / total_population) * 1000, NA),
            pedestrian_rate_per_1000 = ifelse(total_population > 0, (pedestrians_injured / total_population) * 1000, NA),
            cyclist_rate_per_1000 = ifelse(total_population > 0, (cyclists_injured / total_population) * 1000, NA),
            motorist_rate_per_1000 = ifelse(total_population > 0, (motorists_injured / total_population) * 1000, NA),
            injury_fatality_ratio = ifelse(persons_killed > 0, persons_injured / persons_killed, NA)
        )
    
    message("Merged dataset has ", nrow(mvc_final), " rows.")
    
    # Check for tracts with crashes but no population data
    missing_pop <- sum(is.na(mvc_final$total_population))
    if (missing_pop > 0) {
        warning(missing_pop, " tract-year combinations have crashes but no population data. Rates will be NA.")
    }
}, error = function(e) {
    stop("Error in merging with ACS data: ", e$message)
})

# ---------------------------
# 8. Create Final Combined Dataset
# ---------------------------
message("\nCreating final combined dataset...")

tryCatch({
    # 1. Prepare the datasets for joining
    acs_full <- acs %>%
        mutate(geoid = as.character(geoid),
               year = as.integer(year)) %>%
        select(geoid, year, everything())
    
    mvc_final_join <- mvc_final %>%
        mutate(GEOID = as.character(GEOID),
               year = as.integer(year)) %>%
        select(GEOID, year, everything())
    
    # 2. Perform the join
    final_dataset <- acs_full %>%
        left_join(mvc_final_join, by = c("geoid" = "GEOID", "year" = "year"))
    
    # 3. Define the crash-related columns we expect
    crash_cols <- c("total_crashes", "persons_injured", "persons_killed",
                    "pedestrians_injured", "pedestrians_killed",
                    "cyclists_injured", "cyclists_killed",
                    "motorists_injured", "motorists_killed")
    
    # 4. Initialize missing crash columns with NA
    for(col in crash_cols) {
        if(!col %in% names(final_dataset)) {
            final_dataset[[col]] <- NA_real_
        }
    }
    
    # 5. Replace NA crash counts with 0 where we have population data
    # First identify which population column to use
    pop_col <- ifelse("total_population.x" %in% names(final_dataset),
                      "total_population.x",
                      ifelse("total_population" %in% names(final_dataset),
                             "total_population",
                             NA_character_))
    
    if(!is.na(pop_col)) {
        for(col in crash_cols) {
            final_dataset[[col]] <- ifelse(
                is.na(final_dataset[[col]]) & !is.na(final_dataset[[pop_col]]),
                0,
                final_dataset[[col]]
            )
        }
    } else {
        warning("No population column found - skipping NA replacement for crash counts")
    }
    
    # 6. Clean up duplicate columns from join
    if("total_population.y" %in% names(final_dataset)) {
        final_dataset <- final_dataset %>%
            mutate(total_population = coalesce(total_population.x, total_population.y)) %>%
            select(-total_population.x, -total_population.y)
    }
    
    # 7. Calculate rates (only if we have population data)
    if("total_population" %in% names(final_dataset)) {
        final_dataset <- final_dataset %>%
            mutate(
                crash_rate_per_1000 = ifelse(total_population > 0, 
                                             (total_crashes / total_population) * 1000, 
                                             NA_real_),
                injury_rate_per_1000 = ifelse(total_population > 0, 
                                              (persons_injured / total_population) * 1000, 
                                              NA_real_),
                fatality_rate_per_1000 = ifelse(total_population > 0, 
                                                (persons_killed / total_population) * 1000, 
                                                NA_real_),
                pedestrian_rate_per_1000 = ifelse(total_population > 0, 
                                                  (pedestrians_injured / total_population) * 1000, 
                                                  NA_real_),
                cyclist_rate_per_1000 = ifelse(total_population > 0, 
                                               (cyclists_injured / total_population) * 1000, 
                                               NA_real_),
                motorist_rate_per_1000 = ifelse(total_population > 0, 
                                                (motorists_injured / total_population) * 1000, 
                                                NA_real_),
                injury_fatality_ratio = ifelse(persons_killed > 0, 
                                               persons_injured / persons_killed, 
                                               NA_real_)
            )
    } else {
        warning("No population data available - skipping rate calculations")
    }
    
    # 8. Final cleanup
    final_dataset <- final_dataset %>%
        # Remove any duplicate columns from join
        select(-ends_with(".x"), -ends_with(".y")) %>%
        # Ensure consistent column order
        select(geoid, year, total_population, everything())
    
    message("Successfully created final dataset with ", nrow(final_dataset), " rows.")
    message("Sample of crash counts:")
    print(head(final_dataset$total_crashes))
    
}, error = function(e) {
    message("\nFinal error diagnostics:")
    if(exists("final_dataset")) {
        message("Current final_dataset columns: ", paste(names(final_dataset), collapse = ", "))
        message("Current final_dataset dimensions: ", paste(dim(final_dataset), collapse = " x "))
    }
    stop("Error creating final dataset: ", e$message)
})

# ---------------------------
# 9. Save Output
# ---------------------------
message("\nSaving output files...")

tryCatch({
    # Save the MVC aggregated data
    mvc_output_file <- file.path(output_dir, "mvc_tract_agg_2018_2023.csv")
    fwrite(mvc_final, mvc_output_file)
    message("MVC aggregated data saved to: ", mvc_output_file)
    
    # Save the final combined dataset
    combined_output_file <- file.path(output_dir, "acs_mvc_combined_2018_2023.csv")
    fwrite(final_dataset, combined_output_file)
    message("Final combined ACS+MVC dataset saved to: ", combined_output_file)
}, error = function(e) {
    stop("Error saving output files: ", e$message)
})

message("\nScript completed successfully!")