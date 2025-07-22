
# utils_api.R
# Helper functions for API calls and pagination


# ---------------------------
# BUILD ACS VARIABLES
# ---------------------------

#' Build ACS Variable Set
#'
#' Returns a named vector of ACS variable codes for demographics, housing,
#' commuting, and income-related features.
#'
#' @return A named character vector of ACS variable codes.
#' @export
build_acs_variables <- function() {
    vars <- c(
        # Demographics
        age_under_25    = "B01001_003",  # Male < 5 years
        age_65_plus     = "B01001_020",  # Male 65-66
        total_population= "B01003_001",
        
        # Education
        high_school     = "B15003_017",
        bachelors_plus  = "B15003_022",
        
        # Poverty & Income
        below_poverty   = "B17001_002",
        median_income   = "B19013_001",
        income_under_25 = "B19001_002",
        income_over_100 = "B19001_017",
        
        # Housing & Density
        household_size  = "B25010_001",
        housing_units   = "B25001_001",
        vehicle_none    = "B25044_003",
        
        # Employment & Occupation
        management      = "C24010_002",
        sales           = "C24010_014",
        construction    = "C24010_022",
        
        # Commuting Patterns
        commute_car     = "B08134_002",
        commute_subway  = "B08134_010",
        commute_walk    = "B08134_018",
        commute_under_30= "B08303_002",
        commute_over_60 = "B08303_011",
        
        # Race & Ethnicity
        white_alone     = "B02001_002",
        black_alone     = "B02001_003",
        hispanic        = "B03002_012"
    )
    return(vars)
}
