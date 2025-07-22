#!/usr/bin/env Rscript

# 01_fetch_mvc.R - Fetch NYC Motor Vehicle Collision (MVC) data (last 5 years)
# Uses public Socrata token, exports data as .csv and .parquet, and uploads to AWS S3.

# ---------------------------
# 0. Package Setup
# ---------------------------
required_packages <- c("httr", "jsonlite", "data.table", "lubridate", "arrow", "aws.s3")

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
    library(arrow)
    library(aws.s3)
})

# ---------------------------
# 1. Token Setup
# ---------------------------
public_token <- Sys.getenv("OPEN_DATA_PUBLIC")
if (public_token == "") {
    stop("No public API token found. Please set OPEN_DATA_PUBLIC in .Renviron.")
}

# AWS credentials
aws_bucket <- Sys.getenv("AWS_S3_BUCKET")
aws_key <- Sys.getenv("AWS_ACCESS_KEY_ID")
aws_secret <- Sys.getenv("AWS_SECRET_ACCESS_KEY")
aws_region <- Sys.getenv("AWS_DEFAULT_REGION", unset = "us-east-1")

if (aws_bucket == "" || aws_key == "" || aws_secret == "") {
    warning("AWS credentials not found. S3 upload will be skipped.")
}

# ---------------------------
# 2. Fetch Function
# ---------------------------
fetch_mvc_data <- function() {
    base_url <- "https://data.cityofnewyork.us/resource/h9gi-nx95.json"
    all_data <- list()
    limit <- 25000
    max_attempts <- 3
    
    # Dynamic 5-year range
    start_date <- floor_date(Sys.Date() %m-% years(5), "month")
    end_date <- ceiling_date(Sys.Date(), "month") - days(1)
    message(sprintf("Fetching data from %s to %s", start_date, end_date))
    
    # Monthly chunks
    time_chunks <- lapply(seq.Date(start_date, end_date, by = "month"), function(d) {
        start <- format(d, "%Y-%m-%d")
        end   <- format((d %m+% months(1)) - 1, "%Y-%m-%d")
        c(start, end)
    })
    
    for (chunk in time_chunks) {
        message("\nProcessing ", chunk[1], " to ", chunk[2], "...")
        offset <- 0
        continue_fetching <- TRUE
        
        while (continue_fetching) {
            for (attempt in 1:max_attempts) {
                tryCatch({
                    query <- list(
                        `$where` = sprintf(
                            "crash_date between '%sT00:00:00' and '%sT23:59:59'",
                            chunk[1], chunk[2]
                        ),
                        `$limit` = limit,
                        `$offset` = offset
                    )
                    
                    response <- GET(
                        base_url,
                        query = query,
                        add_headers("X-App-Token" = public_token),
                        timeout(30)
                    )
                    
                    if (status_code(response) == 429) stop("Rate limit exceeded (HTTP 429)")
                    stop_for_status(response)
                    
                    current_batch <- fromJSON(content(response, "text", encoding = "UTF-8"))
                    
                    if (length(current_batch) == 0) {
                        continue_fetching <- FALSE
                        break
                    }
                    
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
                    
                    break
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
    date_stamp <- format(Sys.Date(), "%Y_%m_%d")
    
    # Save CSV
    csv_file <- sprintf("data/raw/mvc_%s.csv", date_stamp)
    fwrite(mvc_data, csv_file)
    
    # Save Parquet
    parquet_file <- sprintf("data/raw/mvc_%s.parquet", date_stamp)
    write_parquet(mvc_data, parquet_file)
    
    message(sprintf(
        "\nCompleted in %.1f minutes. Saved as %s (%.1f MB)",
        difftime(Sys.time(), start_time, units = "mins"),
        csv_file,
        file.size(csv_file)/1024/1024
    ))
    
    # ---------------------------
    # 4. Upload to AWS S3
    # ---------------------------
    if (aws_bucket != "" && aws_key != "" && aws_secret != "") {
        message("Uploading files to S3 bucket: ", aws_bucket)
        
        put_object(file = csv_file, object = basename(csv_file), bucket = aws_bucket)
        put_object(file = parquet_file, object = basename(parquet_file), bucket = aws_bucket)
        
        message("Upload to S3 completed.")
    }
    
}, error = function(e) {
    stop("Script failed: ", e$message)
})
