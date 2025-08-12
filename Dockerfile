# Dockerfile for container
#
# Build with : podman build -t soib .
#
#

# Base OS
FROM ubuntu:24.04

# Dependent Packages for all the R packages
RUN apt update
RUN apt install -y r-base
RUN apt install -y libcurl4-openssl-dev
RUN apt install -y libxml2-dev \
        libcurl4-openssl-dev \
        libfontconfig-dev \
        pkgconf \
        libharfbuzz-dev \
        libfribidi-dev \
        libpng-dev \
        libtiff5-dev \
        libjpeg-dev \
        cmake \
        libudunits2-dev \
        libgdal-dev

# R Packages our scripts need
RUN Rscript -e 'install.packages("tidyverse")'
RUN Rscript -e 'install.packages("glue")'
RUN Rscript -e 'install.packages("tictoc")'
RUN Rscript -e 'install.packages("dplyr")'
RUN Rscript -e 'install.packages("peakRAM")'
RUN Rscript -e 'install.packages("lubridate")'
RUN Rscript -e 'install.packages("data.table")'
RUN Rscript -e 'install.packages("sf")'
RUN Rscript -e 'install.packages("reshape2")'
RUN Rscript -e 'install.packages("unmarked")'
RUN Rscript -e 'install.packages("merTools")'
RUN Rscript -e 'install.packages("lme4")'
RUN Rscript -e 'install.packages("arm")'
RUN Rscript -e 'install.packages("VGAM")'

# Static data that's in git
COPY 00_data/analyses_metadata.RData /app/00_data/
COPY 01_analyses_full/specieslists.RData /app/01_analyses_full/
COPY 00_data/species_names.RData /app/00_data/
COPY 00_data/timegroups.RData /app/00_data/
COPY 00_data/current_soib_migyears.RData /app/00_data/

# Data files. Whatever we package here is inside the container, so
# makes it easier to manage.  Keep an eye on the size so it doesn't
# blow up
COPY 01_analyses_full/dataforanalyses.RData-metadata /app/01_analyses_full/
# We don't need -data right now. If we don't ship _opt, we need to
# ship/create random ids
COPY 01_analyses_full/dataforanalyses.RData-data /app/01_analyses_data/
COPY 01_analyses_full/dataforsim/data1.RData_opt /app/01_analyses_full/dataforsim/

# NOTE: keeping data inside the container is a policy thing

# Our R scripts
COPY p3s1.R /app/p3s1.R
COPY 00_scripts/run_species_trends_container.R /app/00_scripts/
COPY 00_scripts/00_functions.R /app/00_scripts/

# Set working directory
WORKDIR /app

# Command to run application
ENTRYPOINT ["Rscript", "p3s1.R" ]
