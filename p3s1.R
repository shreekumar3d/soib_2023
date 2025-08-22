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

# We pass results back to host using the "output" directory.
# The container doesn't have it. It has to be bound by the user
# while starting the container. We check this exists
# Ideally we'd have to check whether it's writable, and doesn't
# have any funky permissions that break our scripts
if (!dir.exists("output")) {
  message(paste("Output directory does not exist. Please ensure it is mounted"))
  quit()
}

# Source config file that can define 'threads' and
# 'species_to_process'. Anything else there is ignored
source("output/config.R")

library(parallel)

# threads may be defined in config file
if(!exists('threads')) {
  worker_procs <- parallel::detectCores()/2
  message("Using autodetected threads: ", worker_procs)
} else {
  message("Using configured threads: ", threads)
  worker_procs <- as.integer(threads)
}

if(!exists('species_to_process')) {
  message("Processing ALL species")
  species_to_process <- c()
} else {
  message("Processing species from config:")
  for(sp in species_to_process) {
    message("  ", sp)
  }
}

args = commandArgs(trailingOnly=TRUE)
if(length(args)>=1) {
  worker_procs <- as.integer(args[1])
  message("Using command line specified threads: ", worker_procs)
}


# necessary packages, functions/scripts, data
library(tidyverse)
library(glue)
library(tictoc)

source("00_scripts/00_functions.R")

load("00_data/analyses_metadata.RData")
save(analyses_metadata, file = "output/t.RData")

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

message('Running Part 3, Step 1')
cur_mask <- "none" # analysis for full country (not masks)
tic(glue("Species trends for full country (sims {min(my_assignment)}:{max(my_assignment)})"))
source("00_scripts/run_species_trends_container.R")
toc()
