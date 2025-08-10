# Very similar to opt-dataforanalyses.R, and must
# be run after that.
# Uses species name and timegroup maps from that run
#
# Input:
#   ./01_analyses_full/dataforsim/data1.RData
#   00_data/species_names.RData
#   00_data/timegroups.RData
#
# Output:
#   ./01_analyses_full/dataforsim/data1.RData_opt
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

tic("Loading dataset")
load("./01_analyses_full/dataforsim/data1.RData")
toc()
load("00_data/species_names.RData")
load("00_data/timegroups.RData")

before = as.numeric(object.size(data_filt))
message(paste("Size of data =", before))
print(sapply(data_filt,class))

# Map species names into indices inside a table
species_index <- match(data_filt$COMMON.NAME, species_names$COMMON.NAME)
data_filt$COMMON.NAME <- species_index
print(paste("Remap Status:", all(data_filt$COMMON.NAME == species_names[species_index,1])))

#print(timegroups_names)
timegroups_index <- match(data_filt$timegroups, timegroups_names$timegroups)
data_filt$timegroups <- timegroups_index

data_filt$gridg0 <- as.integer(data_filt$gridg0)
data_filt$gridg1 <- as.integer(data_filt$gridg1)
data_filt$gridg2 <- as.integer(data_filt$gridg2)
data_filt$gridg3 <- as.integer(data_filt$gridg3)
data_filt$gridg4 <- as.integer(data_filt$gridg4)

data_filt$ALL.SPECIES.REPORTED <- as.integer(data_filt$ALL.SPECIES.REPORTED)
data_filt$month <- as.integer(data_filt$month)
data_filt$year <- as.integer(data_filt$year)

# OBSERVATION.COUNT values of "X" convert to 0
data_filt$OBSERVATION.COUNT[data_filt$OBSERVATION.COUNT == "X"] <- "1"
storage.mode(data_filt$OBSERVATION.COUNT) <- "integer"

data_filt$group.id <- convert_group_id(data_filt$group.id)
data_filt$OBSERVER.ID <- convert_observer_id(data_filt$OBSERVER.ID)
print(sapply(data_filt,class))

tic("Saving remapped dataset")
save(data_filt, file= "./01_analyses_full/dataforsim/data1.RData_opt")
toc()

# clear data
rm(data_filt)

tic("Loading remapped dataset")
load("./01_analyses_full/dataforsim/data1.RData_opt")
toc()
print(sapply(data_filt,class))

after = as.numeric(object.size(data_filt))
message(paste("Size of remapped data =", after))
message(paste("RAM Savings = ", (before-after)/1e9, "GB", ((before-after)/before)*100.0), "%")

#
#Loading dataset: 14.57 sec elapsed
#Size of data = 1553723928
#Saving remapped dataset: 12.838 sec elapsed
#Loading remapped dataset: 1.461 sec elapsed
#Size of remapped data = 777228776
#RAM Savings =  0.776495152 GB 49.9763914300739%
#
