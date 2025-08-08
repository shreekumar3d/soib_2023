#
# Script to run Part 3 Step 1
# i.e. computing species trends
# for whole country
# and first random set (my_assignment = 1:1)
#
# Primarily used for 2 purposes:
# 1. Ensure sanity of setup (compare trends1.csv with reference)
# 2. Benchmark execution performance
#

# necessary packages, functions/scripts, data
library(tidyverse)
library(glue)
library(tictoc)

source("00_scripts/00_functions.R")

load("00_data/analyses_metadata.RData")


# full country runs -------------------------------------------------------

my_assignment <- 1:1

# PART 3 (run) ------------------------------------------------------------------

# STEP 1: Run trends models for all selected species
# Requires:
# - tidyverse, tictoc, lme4, VGAM, parallel, foreach, doParallel
# - data files:
#   - "dataforsim/dataX.RData"
#   - "specieslists.RData"
# Outputs:
# - "trends/trendsX.csv" files

message('Step 1')
cur_mask <- "none" # analysis for full country (not masks)
tic(glue("Species trends for full country (sims {min(my_assignment)}:{max(my_assignment)})"))
source("00_scripts/run_species_trends.R")
toc()
