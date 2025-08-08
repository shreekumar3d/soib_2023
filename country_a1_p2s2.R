# necessary packages, functions/scripts, data
library(tidyverse)
library(glue)
library(tictoc)

source("00_scripts/00_functions.R")

load("00_data/analyses_metadata.RData")


# full country runs -------------------------------------------------------

my_assignment <- 1:1 # CHANGE FOR YOUR SUBSET


# PART 2 (subsample) ------------------------------------------------------------------

# STEP 2: Create subsampled data files using subsampled GROUP.IDs
# Requires:
# - tidyverse, tictoc
# - data files:
#   - "dataforanalyses.RData"
#   - "randomgroupids.RData"
# Outputs:
# - "dataforsim/dataX.RData files
message('Step 1')
cur_mask <- "none" # analysis for full country (not masks)
tic(glue("Generated subsampled data for full country (sims {min(my_assignment)}:{max(my_assignment)})"))
source("00_scripts/create_random_datafiles.R")
toc()
