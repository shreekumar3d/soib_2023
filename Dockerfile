# Dockerfile for container. Build with podman
# Reduced size by building over alpine
#
# Build with : podman build -t soib .
#
# podman save -o soib.tar localhost/soib:latest
#
# Image size:
# - 450 MB without data (R+deps+base linux)
# - 840 MB with data
#

#FROM alpine:latest actually resolves to ?
#Next step would be to tie down package versions
FROM alpine:latest

ARG R_VERSION
ENV R_VERSION ${R_VERSION:-4.5.0}
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV CRAN https://cran.r-project.org
ENV R_DAILY_URL https://stat.ethz.ch/R/daily

# Dependent Packages for all the R packages, plus the R packages themselves as
# one single layer
# NOTE: gdal-dev is added later again as sf has some shared lib dependency on this
# FIXME: Why is tidyverse coming from cloud-r project rather than cran project ?
RUN apk update && \
    apk add R cmake R-dev linux-headers g++ && \
    apk add udunits udunits-dev gdal-dev proj proj-dev && \
    apk add geos geos-dev && \
    apk add tzdata && \
    apk add libxml2-dev && \
    apk add fontconfig-dev && \
    apk add harfbuzz-dev && \
    apk add fribidi-dev && \
    apk add openssl-dev && \
    apk add curl-dev && \
    Rscript -e 'install.packages("tictoc",repos = "http://cran.us.r-project.org")' && \
    Rscript -e 'install.packages("dplyr", repos = "http://cran.us.r-project.org")' && \
    Rscript -e 'install.packages("peakRAM", repos = "http://cran.us.r-project.org")' && \
    Rscript -e 'install.packages("lme4", repos = "http://cran.us.r-project.org")' && \
    Rscript -e 'install.packages("arm", repos = "http://cran.us.r-project.org")' && \
    Rscript -e 'install.packages("VGAM", repos = "http://cran.us.r-project.org")' && \
    Rscript -e 'install.packages("merTools", repos = "http://cran.us.r-project.org")' && \
    Rscript -e 'install.packages("unmarked", repos = "http://cran.us.r-project.org")' && \
    Rscript -e 'install.packages("reshape2", repos = "http://cran.us.r-project.org")' && \
    Rscript -e 'install.packages("sf", repos = "http://cran.us.r-project.org")' && \
    Rscript -e 'install.packages("data.table", repos = "http://cran.us.r-project.org")' && \
    Rscript -e 'install.packages("lubridate", repos = "http://cran.us.r-project.org")' && \
    Rscript -e 'install.packages("glue", repos = "http://cran.us.r-project.org")' && \
    Rscript -e 'install.packages("tidyverse", dependencies=TRUE, type="source", repos="https://cloud.r-project.org")' && \
    apk del *-dev linux-headers g++ cmake && \
    apk add gdal-dev && \
    rm -rf /var/cache/apk/*

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

ENV OMP_NUM_THREADS=1
# Command to run application
ENTRYPOINT ["Rscript", "p3s1.R" ]
