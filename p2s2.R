library(tidyverse)
library(glue)
library(tictoc)
# for parallel iterations
library(furrr)
library(parallel)

source("00_scripts/00_functions.R")


# Is the current run for a new major SoIB version (every 3-4 years), 
# or for an interannual update (every year between major versions)?
# testing git
interannual_update = TRUE


# PART 0 (paths) ----------------------------------------------------------

#source("00_scripts/01_create_metadata.R")

# PART 2 (subsample) ------------------------------------------------------------------

# Preparing data for trends analysis

# STEP 2: Create subsampled data files using subsampled GROUP.IDs
# Run:
# - after above step (P2, S1)
# Requires:
# - tidyverse, tictoc
# - data files:
#   - "dataforanalyses.RData" for whole country and individual mask versions
#   - "randomgroupids.RData" for whole country and individual mask versions
# Outputs:
# - "dataforsim/dataX.RData" for whole country and individual mask versions

load("00_data/analyses_metadata.RData")


cur_mask <- "none"
my_assignment <- 1:200 # CHANGE FOR YOUR SUBSET
tic(glue("Generated subsampled data for full country (# {min(my_assignment)}:{max(my_assignment)})"))
source("00_scripts/optimize_assignment_datafiles.R")
toc() # 124 min (~ 2 h) for 100

cur_mask <- "woodland"
tic(glue("Generated subsampled data for {cur_mask}"))
source("00_scripts/optimize_assignment_datafiles.R")
toc() 

cur_mask <- "cropland"
tic(glue("Generated subsampled data for {cur_mask}"))
source("00_scripts/optimize_assignment_datafiles.R")
toc() # 4.75 hours

cur_mask <- "ONEland"
tic(glue("Generated subsampled data for {cur_mask}"))
source("00_scripts/optimize_assignment_datafiles.R")
toc() # 3 hours

cur_mask <- "PA"
tic(glue("Generated subsampled data for {cur_mask}"))
source("00_scripts/optimize_assignment_datafiles.R")
toc() 


# states
not_my_states <- c(
  c("Telangana", "Chhattisgarh", "Jammu and Kashmir", "Assam",  "Andhra Pradesh", "Puducherry", 
    "Madhya Pradesh"),
  c("Gujarat", "Uttarakhand", "West Bengal", "Maharashtra", "Karnataka", "Kerala", "Tamil Nadu", 
    "Meghalaya", "Ladakh")
)

tic("Generated subsampled data for all states") # 4 hours for 21 states

analyses_metadata %>% 
  filter(MASK.TYPE == "state") %>% 
  distinct(MASK) %>% 
  filter(!MASK %in% not_my_states) %>% 
  pull(MASK) %>% 
  # walking over each state
  walk(~ {
    
    tic(glue("Generated subsampled data for {.x} state"))
    assign("cur_mask", .x, envir = .GlobalEnv)
    source("00_scripts/optimize_assignment_datafiles.R")
    toc()
    
  })

toc()
rm(not_my_states)
