#!/usr/bin/env Rscript

# 01_fetch_mvc.R - Fetch NYC Motor Vehicle Collision (MVC) data for 2018–2023
# Uses only a public Socrata application token
# Stores raw data in data/raw/mvc_<DATE>.csv

# ---------------------------
# 0. Package Setup
# ---------------------------
required_packages <- c("httr", "jsonlite", "data.table", "lubridate")

install_if_missing <- function(pkg) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
        install.packages(pkg, repos = "https://cloud.r-project.org")
    }
}

invisible(lapply(required_packages, install_if_missing))

suppressPackageStartupMessages({
    library(httr)
    library(jsonlite)
    library(data.table)
    library(lubridate)
})

# ---------------------------
# 1. Token Setup
# ---------------------------
public_token <- Sys.getenv("OPEN_DATA_PUBLIC")
if (public_token == "") {
    stop("No public API token found. Please set OPEN_DATA_PUBLIC in .Renviron.")
}

# ---------------------------
# 2. Fetch Function
# ---------------------------
fetch_mvc_data <- function() {
    base_url <- "https://data.cityofnewyork.us/resource/h9gi-nx95.json"
    all_data <- list()
    limit <- 25000
    max_attempts <- 3
    
    # Split date range into manageable chunks
    time_chunks <- lapply(seq.Date(from = as.Date("2018-01-01"),
                                   to   = as.Date("2023-12-01"),
                                   by   = "month"),
                          function(d) {
                              start <- format(d, "%Y-%m-%d")
                              end   <- format((d %m+% months(1)) - 1, "%Y-%m-%d")
                              c(start, end)
                          })
    head(time_chunks, 3)
    
    for (chunk in time_chunks) {
        message("\nProcessing ", chunk[1], " to ", chunk[2], "...")
        offset <- 0
        continue_fetching <- TRUE
        
        while (continue_fetching) {
            for (attempt in 1:max_attempts) {
                tryCatch({
                    # query
                    query <- list(
                        `$where` = sprintf(
                            "crash_date between '%sT00:00:00' and '%sT23:59:59'",
                            chunk[1], chunk[2]
                        ),
                        `$limit` = limit,
                        `$offset` = offset,
                        `$order` = "crash_date"
                    )
                    
                    # API request with public token
                    response <- GET(
                        base_url,
                        query = query,
                        add_headers("X-App-Token" = public_token),
                        timeout(30)
                    )
                    
                    if (status_code(response) == 429) {
                        stop("Rate limit exceeded (HTTP 429)")
                    }
                    stop_for_status(response)
                    
                    # Parse response
                    current_batch <- fromJSON(content(response, "text", encoding = "UTF-8"))
                    
                    if (length(current_batch) == 0) {
                        continue_fetching <- FALSE
                        break
                    }
                    
                    # Convert and clean
                    current_batch <- as.data.table(current_batch)
                    setnames(current_batch, tolower(names(current_batch)))
                    
                    all_data[[length(all_data) + 1]] <- current_batch
                    message(sprintf("Fetched %d records (Total: %d)",
                                    nrow(current_batch),
                                    sum(sapply(all_data, nrow))))
                    
                    if (nrow(current_batch) < limit) {
                        continue_fetching <- FALSE
                    } else {
                        offset <- offset + limit
                    }
                    
                    break # success, break retry loop
                }, error = function(e) {
                    if (attempt == max_attempts) {
                        stop("Failed after ", max_attempts, " attempts: ", e$message)
                    }
                    message("Attempt ", attempt, " failed: ", e$message)
                    Sys.sleep(5 * attempt)
                })
            }
            if (continue_fetching) Sys.sleep(1)
        }
    }
    
    if (length(all_data) == 0) stop("No data received from API")
    
    message("\nCombining ", length(all_data), " batches...")
    combined <- rbindlist(all_data, use.names = TRUE, fill = TRUE)
    
    if ("crash_date" %in% names(combined)) {
        combined[, crash_date := as.POSIXct(crash_date, format = "%Y-%m-%dT%H:%M:%S")]
    }
    
    return(combined)
}

# ---------------------------
# 3. Main Execution
# ---------------------------
tryCatch({
    message("Starting MVC data fetch at ", Sys.time())
    start_time <- Sys.time()
    
    mvc_data <- fetch_mvc_data()
    
    if (nrow(mvc_data) == 0) stop("Final dataset is empty")
    message("\nSuccessfully retrieved ", nrow(mvc_data), " total records")
    
    dir.create("data/raw", recursive = TRUE, showWarnings = FALSE)
    out_file <- sprintf("data/raw/mvc_%s.csv", format(Sys.Date(), "%Y_%m_%d"))
    fwrite(mvc_data, out_file)
    
    message(sprintf(
        "\nCompleted in %.1f minutes. Saved to %s (%.1f MB)",
        difftime(Sys.time(), start_time, units = "mins"),
        out_file,
        file.size(out_file)/1024/1024
    ))
}, error = function(e) {
    stop("Script failed: ", e$message)
})
