FROM rocker/shiny:4.3.3

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libxml2-dev \
    libssl-dev \
    libcurl4-openssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Install R packages
RUN R -e "install.packages('BiocManager', repos='https://cran.rstudio.com/')"

# Set environment variables for C++11 support
ENV PKG_CXXFLAGS="-std=c++11" \
    CXX11=TRUE \
    CXX11STD="-std=c++11" \
    CXX1X=TRUE \
    CXX1XSTD="-std=c++11"

# Install Bioconductor packages
RUN R -e "BiocManager::install(c('msa', 'Biostrings'), update = FALSE, ask = FALSE)"

# Install CRAN packages
RUN R -e "install.packages(c('shiny', 'base64enc', 'digest', 'jsonlite', 'DBI', 'RSQLite'), repos='https://cran.rstudio.com/', dependencies=TRUE)"

# Copy application files
COPY app /srv/shiny-server/app

# Make the app available at port 3838
EXPOSE 3838

# Run the application
CMD ["R", "-e", "shiny::runApp('/srv/shiny-server/app', host = '0.0.0.0', port = 3838)"] 