#
# Testbench for last mile speed optimizations
# expand_dt() and datay computations in 00_scripts/00_functions.R
#
# Helps measure the correctness and impact of these
# optimizations
#
# Methodology: execute before(existing code), and after(proposed
# optimizations) methods. Compare in terms of exact same results
# returned (required) and time saving.
#
library(dplyr)
library(tibble)
library(tictoc)
library(data.table)
require(tidyverse)
require(dtplyr)
require(data.table)

#
# expand_dt is a direct copy from 00_scripts/00_functions.R
# with some comments
#
expand_dt_local = function(data, species, singleyear = FALSE) {

  setDT(data)

    #tic("convert to data table")
    data <- data %>%
      lazy_dt(immutable = FALSE) |>
      mutate(across(contains("gridg"), ~ as.factor(.))) %>%
      {if (singleyear == FALSE) {
        mutate(., timegroups = as.factor(timegroups))
      } else if (singleyear == TRUE) {
        .
      }} |>
      as.data.table()
    #toc()

  # Get distinct rows and filter based on a condition
  # (using base data.table because lazy_dt with immutable == FALSE would
  # modify data even though we are assigning to checklistinfo.
  # and immutable == TRUE copies the data and this is a huge bottleneck)
  # considers only complete lists

# All columns in data
#
# COMMON.NAME            OBSERVATION.COUNT  OBSERVER.ID
# ALL.SPECIES.REPORTED   group.id           month
# year                   no.sp              gridg0
# gridg1                 gridg2             gridg3
# gridg4                 timegroups
# (14 fields)

# why doesn't checklistinfo look at gridg0 ?
# It also doesn't look at these, but that's obvious?
#   - OBSERVATION.COUNT
#   - COMMON.NAME
  #tic("checklistinfo unique")
  if (singleyear == FALSE) {

    checklistinfo <- unique(data[,
                                 .(gridg1, gridg2, gridg3, gridg4, ALL.SPECIES.REPORTED, OBSERVER.ID,
                                   group.id, month, year, no.sp, timegroups)
    ])[
      # filter
      ALL.SPECIES.REPORTED == 1
    ]
  } else if (singleyear == TRUE) {

    checklistinfo <- unique(data[, 
                                 .(gridg1, gridg2, gridg3, gridg4, ALL.SPECIES.REPORTED, OBSERVER.ID, 
                                   group.id, month, year, no.sp)
    ])[
      # filter
      ALL.SPECIES.REPORTED == 1
    ]

  }
  #toc()

  #message("before filter checklistinfo has ", nrow(checklistinfo), " rows")
  #tic("checklistinfo SD subset")
  checklistinfo <- checklistinfo[
    , 
    .SD[1], # subset of data
    by = group.id
  ]
  #toc()

  #message("checklistinfo has ", nrow(checklistinfo), " rows")
  # expand data frame to include the bird species in every list
  
  join_by_temp <- if (singleyear == FALSE) {
    c("group.id", "gridg1", "gridg2", "gridg3", "gridg4",
      "ALL.SPECIES.REPORTED", "OBSERVER.ID", "month", "year", 
      "no.sp", "timegroups", "COMMON.NAME")
  } else if (singleyear == TRUE) {
    c("group.id", "gridg1", "gridg2", "gridg3", "gridg4",
      "ALL.SPECIES.REPORTED", "OBSERVER.ID", "month", "year", 
      "no.sp","COMMON.NAME")
  }

  #tic("data2")
    data2 = checklistinfo %>% 
      lazy_dt(immutable = FALSE) |> 
      mutate(COMMON.NAME = species) %>% 
      left_join(data |> lazy_dt(immutable = FALSE),
                by = join_by_temp) %>%
      dplyr::select(-c("COMMON.NAME","gridg2","gridg4","OBSERVER.ID",
                       "ALL.SPECIES.REPORTED","group.id","year")) %>% 
      # deal with NAs (column is character)
      mutate(OBSERVATION.COUNT = case_when(is.na(OBSERVATION.COUNT) ~ 0,
                                           OBSERVATION.COUNT != "0" ~ 1, 
                                           TRUE ~ as.numeric(OBSERVATION.COUNT))) |> 
      as_tibble()
  #toc()
  rm(join_by_temp)
  
  return(data2)
}
source("00_scripts/00_functions.R")
load("./01_analyses_full/species_names.RData")

# Get global context 
cur_metadata <- get_metadata("none")
speclist_path <- cur_metadata$SPECLISTDATA.PATH
databins_path <- cur_metadata$DATA.PATH # for databins
load(speclist_path)
to_run <- (1 %in% specieslist$ht) | (1 %in% specieslist$rt) |
  (1 %in% restrictedspecieslist$ht) | (1 %in% restrictedspecieslist$rt)

lsa = specieslist %>% filter(!is.na(ht) | !is.na(rt))
listofspecies = c(lsa$COMMON.NAME, restrictedspecieslist$COMMON.NAME)

message("Number of species=", length(listofspecies))
#launch_species <- "Coppersmith Barbet"
#species_index <- which(species_names$COMMON.NAME==launch_species)
#message("species: ", launch_species, " index =", species_index)

tic("load data")
load("data/01_analyses_full/dataforanalyses.RData-data_opt")
load("data/01_analyses_full/rgids-1.RData")
load("data/01_analyses_full/timegroups.RData")
toc()


data_filt <- data[data$group.id %in% randomgroupids, ]
data_filt$timegroups <- timegroups_names$timegroups[data_filt$timegroups]

print(sapply(data_filt, class))

tic("master_table")
master_table <- data_filt %>%
  mutate(key = gridg3 * 1000 + month)
toc()

tic("Key mapping per species")
species_to_keys <- master_table %>%
  dplyr::select(key, COMMON.NAME) %>%  # Only keeps these 2 columns
  group_by(COMMON.NAME) %>%
  summarise(values = list(sort(unique(key))), .groups = 'drop') %>%
  deframe()  # Convert to named list
toc()

# setup for efficiency
setDT(master_table)
setkey(master_table, key)

#
# Testing phase!
#

do_match <- FALSE # TRUE to compare before/after - will SLOW down execution
slow_total <- 0
fast_total <- 0
ed_total <- 0

for (launch_species in listofspecies) {
  species_index <- which(species_names$COMMON.NAME==launch_species)
  message("species: ", launch_species, " index =", species_index)
  tic("  data1 SLOW")
  # Original calculation (slow calculation?)
  data1 = data_filt %>%
    filter(COMMON.NAME == species_index) %>%
    distinct(gridg3, month) %>%
    left_join(data_filt)
  slow_timing <- toc()
  slow_elapsed <- (slow_timing$toc - slow_timing$tic)
  slow_total <- slow_total + slow_elapsed

  #print(sapply(data1,class))
  message("  data1 has " ,nrow(data1), " rows")

  # Fast calculation
  tic("  data1 FAST")
  this_species_keys = species_to_keys[[as.character(species_index)]]
  range <- master_table[J(this_species_keys), nomatch=0]
  #range <- range[-1, ] # remove first row (uncomment to test only)
  fast_timing <- toc()
  fast_elapsed <- (fast_timing$toc - fast_timing$tic)
  fast_total <- fast_total + fast_elapsed

  message("  range has " ,nrow(range), " rows")
  #print(sapply(range,class))

  if(do_match) {
    range$key <- NULL # remove extra column for comparison
    if(isTRUE(all_equal(data1, range, ignore_col_order = TRUE, ignore_row_order = TRUE))) {
      message("  fast data1 computation : MATCHES")
    } else {
      message("  fast data1 computation : Doesn't match")
    }
  }

  tic("  ed SLOW")
  ed = expand_dt_local(data1, species_index)
  ed_timing <- toc()
  ed_elapsed <- (ed_timing$toc - ed_timing$tic)
  ed_total <- ed_total + ed_elapsed
}

message("datay_input_total : ", slow_total)
message("fast_total : ", fast_total)
message("ed_total : ", ed_total)
#print(sapply(ed,class))
#message("ed rows=", nrow(ed))

