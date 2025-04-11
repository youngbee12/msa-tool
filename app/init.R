# This is the init.R file for package dependencies

# First, install BiocManager if not available
if (!requireNamespace("BiocManager", quietly = TRUE)) {
    install.packages("BiocManager", repos="https://cran.rstudio.com/")
}

# Set compiler flags for C++11 support
Sys.setenv(PKG_CXXFLAGS="-std=c++11")
Sys.setenv(CXX11=TRUE)
Sys.setenv(CXX11STD="-std=c++11")
Sys.setenv(CXX1X=TRUE)
Sys.setenv(CXX1XSTD="-std=c++11")

# Install system dependencies
system("apt-get update && apt-get install -y libxml2-dev")

# Install Bioconductor packages
BiocManager::install(c("msa", "Biostrings"), update = FALSE, ask = FALSE)

# Install CRAN packages
install.packages(c(
    "shiny",
    "base64enc",
    "digest",
    "jsonlite",
    "DBI",
    "RSQLite"
), repos="https://cran.rstudio.com/", dependencies=TRUE)

