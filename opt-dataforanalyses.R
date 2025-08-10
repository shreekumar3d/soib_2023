#
# Reduce RAM requirement to store dataforanalyses.RData
# This file is split to data and metadata parts to avoid unnecessary data
# load of data in run_species_trends
#
# Remaps fields to achieve this.
# Major improvements
# - character(strings) are converted to integer. To get back the original
#   string, you need to lookup using a separate table, which is also stored.
# - numerics are changed to integer, as there are no floating points values
#   in this dataset
# - grid ids also become integers
# - group id and observer id are mapped to integers using straightforward
#   transformations, noting that the IDs don't have more than 9 digits.
#
# Resulting optimized file saves ~50% RAM, loads ~10X faster from storage.
#
library("tictoc")
library("dplyr")

convert_observation_count <- function(cstr) {
  count <- ifelse(cstr=="X",1L,as.integer(cstr));
  return(count)
}

convert_group_id <- function(x) {
  base <- ifelse(substr(x,1,1)=="S",0L,1000000000L) # G=>giga base
  return(base + as.integer(substr(x,2,12)))
}

convert_observer_id <- function(x) {
  return(as.integer(substr(x,5,15)))
}

src_dataset <- "01_analyses_full/dataforanalyses.RData-data"
tgt_dataset <- "01_analyses_full/dataforanalyses.RData-data_opt"
species_map <- "00_data/species_names.RData"
timegroups_map <- "00_data/timegroups.RData"
message(paste("Loading dataset",src_dataset))
tic("Loading dataset")
load(src_dataset)
toc()

before = as.numeric(object.size(data))
message(paste("Size of data =", before))
print(sapply(data,class))

# Map species names into indices inside a table
species_names <- distinct(data,COMMON.NAME)
species_index <- match(data$COMMON.NAME, species_names$COMMON.NAME)
data$COMMON.NAME <- species_index
print(paste("Remap Status:", all(data$COMMON.NAME == species_names[species_index,1])))

timegroups_names <- distinct(data,timegroups)
timegroups_index <- match(data$timegroups, timegroups_names$timegroups)
data$timegroups <- timegroups_index

data$gridg0 <- as.integer(data$gridg0)
data$gridg1 <- as.integer(data$gridg1)
data$gridg2 <- as.integer(data$gridg2)
data$gridg3 <- as.integer(data$gridg3)
data$gridg4 <- as.integer(data$gridg4)

data$ALL.SPECIES.REPORTED <- as.integer(data$ALL.SPECIES.REPORTED)
data$month <- as.integer(data$month)
data$year <- as.integer(data$year)

# OBSERVATION.COUNT values of "X" convert to 1
data$OBSERVATION.COUNT[data$OBSERVATION.COUNT == "X"] <- "1"
storage.mode(data$OBSERVATION.COUNT) <- "integer"

data$group.id <- convert_group_id(data$group.id)
data$OBSERVER.ID <- convert_observer_id(data$OBSERVER.ID)
print(sapply(data,class))

message(paste("Saving remapped dataset",tgt_dataset))
message(paste("Saving species mapping to ",species_map))
message(paste("Saving timegroups mapping to ",timegroups_map))
tic("Saving remapped dataset")
save(data, file=tgt_dataset)
save(species_names, file=species_map)
save(timegroups_names, file=timegroups_map)
toc()

# clear data
rm(data)

message(paste("Loading remapped dataset",tgt_dataset))
tic("Loading remapped dataset")
load(tgt_dataset)
toc()
print(sapply(data,class))

after = as.numeric(object.size(data))
message(paste("Size of remapped data =", after))
message(paste("RAM Savings = ", (before-after)/1e9, "GB", ((before-after)/before)*100.0), "%")

#
# Expected improvements:
#
#Size of data = 4301565656
#Size of remapped data = 2147397464
#RAM Savings =  2.154168192 GB 50.0787007399336%

