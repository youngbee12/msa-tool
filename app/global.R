# Enable error logging
options(shiny.sanitize.errors = FALSE)
options(warn = 1)

# Install BiocManager if not available
if (!requireNamespace("BiocManager", quietly = TRUE)) {
    install.packages("BiocManager")
}

# Install Bioconductor packages if not available
bioc_packages <- c("msa", "Biostrings")
for (pkg in bioc_packages) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
        message(sprintf("Installing Bioconductor package: %s", pkg))
        BiocManager::install(pkg, update = FALSE, ask = FALSE)
    }
}

# Required packages
required_packages <- c(
    "shiny",
    "msa",
    "Biostrings",
    "base64enc",
    "digest",
    "leaflet",
    "leaflet.extras",
    "jsonlite",
    "DBI",
    "RSQLite"
)

# Load required packages with error handling
for (pkg in required_packages) {
    tryCatch({
        suppressPackageStartupMessages(library(pkg, character.only = TRUE))
    }, error = function(e) {
        message(sprintf("Error loading package %s: %s", pkg, e$message))
        # For Bioconductor packages, try installing again if loading fails
        if (pkg %in% bioc_packages) {
            message(sprintf("Attempting to reinstall Bioconductor package: %s", pkg))
            BiocManager::install(pkg, update = FALSE, ask = FALSE)
            suppressPackageStartupMessages(library(pkg, character.only = TRUE))
        } else {
            stop(sprintf("Failed to load required package: %s", pkg))
        }
    })
}

# Global configurations
options(shiny.maxRequestSize = 30*1024^2)  # Set max file upload size to 30MB

# Get the app directory for file paths
app_dir <- getwd()
if (dir.exists("app")) {
    app_dir <- file.path(app_dir, "app")
}

# Initialize SQLite database for visitor tracking
db_path <- file.path(app_dir, "visitors.db")

# Function to safely initialize database
init_database <- function() {
    tryCatch({
        if (!file.exists(db_path)) {
            con <- dbConnect(SQLite(), db_path)
            dbExecute(con, "
                CREATE TABLE visitors (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    ip TEXT,
                    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
                    country TEXT,
                    city TEXT,
                    latitude REAL,
                    longitude REAL
                )
            ")
            dbDisconnect(con)
        }
    }, error = function(e) {
        message("Warning: Could not initialize visitor database: ", e$message)
        # 继续运行，不要因为访客追踪失败而停止应用
    })
}

# Initialize database
init_database()

# Ensure the database is writable
if (file.exists(db_path)) {
    Sys.chmod(db_path, mode = "0666")
}

# Function to get IP geolocation with caching and error handling
ip_cache <- new.env(hash = TRUE)

get_ip_info <- function(ip) {
    tryCatch({
        # Check cache first
        if (exists(ip, envir = ip_cache)) {
            return(get(ip, envir = ip_cache))
        }
        
        # If not in cache, fetch from API
        url <- paste0("http://ip-api.com/json/", ip)
        response <- fromJSON(url)
        
        if (response$status == "success") {
            result <- list(
                country = response$country,
                city = response$city,
                lat = response$lat,
                lon = response$lon
            )
            # Cache the result
            assign(ip, result, envir = ip_cache)
            return(result)
        }
        return(NULL)
    }, error = function(e) {
        message("Error getting IP info: ", e$message)
        return(NULL)
    })
} 