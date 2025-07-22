
# utils_api.R
# Helper functions for API calls and pagination

library(httr)
library(jsonlite)

#' Load Requirements
#'
#' This function checks if required packages are installed, installs them if they are missing, 
#' and then loads them for the script.
#' 
#' @param packages A character vector of the names of required packages.
#' @examples
#' \dontrun{
#' packages <- c("httr", "jsonlite")
#' load_reqs(packages)
#' }
load_reqs <- function(packages) {
    # check all libraries installed
    install_if_missing <- function(pkg) {
        if (!requireNamespace(pkg,
                              quietly = TRUE)) {
            install.packages(pkg) # install if missing
        }
    }    
    
    invisible(lapply(packages, install_if_missing))
    
    # load packages
    for (pkg in packages) {
        library(pkg, character.only = TRUE)
    }
    
    # source
    utils_file <- "R/utils_api.R"
    if (!file.exists(utils_file)) {
        warning(utils_file, " not found in R/ directory.\n")
    } else {
        source(utils_file)
    }
}

#' Fetch All from API
#' 
#' This function fetches all results from Socrata API using limits and offset
#' 
#' @param base_url 
#' @param query
#' @param limit
#' 
#' @example 
#' \dontrun{
#' mvc_data <- api_fetch_all(mvc_url_base, query, limit)
#' }
api_fetch_all <- function(base_url, query, limit=50000) {
    all_data <- list()
    offset <- 0
    repeat {
        url <- paste0(base_url, "?", query, "&$offset=", offset)
        message(sprintf("Fetching records %d to %d...", offset + 1, offset + limit))
        res <- GET(url)
        stop_for_status(res)
        data <- fromJSON(content(res, "text", encoding = "UTF-8"))
        if (length(data) == 0) break
        all_data <- append(all_data, list(data))
        offset <- offset + limit
        if (length(data) < limit) break
    }
    return(do.call(rbind, all_data))
}