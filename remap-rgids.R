# Remaps randomgroupids to 1000 separate files
# with integer mapped random group ids.
# Each run needs only one file
library("tictoc")

print("loading random group ids...")
tic("time")
load("./01_analyses_full/randomgroupids.RData")
toc()

convert_group_id <- function(x) {
  base <- ifelse(substr(x,1,1)=="S",0L,1000000000L) # G=>giga base
  return(base + as.integer(substr(x,2,12)))
}

for (i in 1:1000) {
  remap <- convert_group_id(randomgroupids[,i])
  this_assignment <- data.frame(group.id = remap)
  print(paste("Random group iteration:", i, "of 1000"))
  save(this_assignment, file=paste0("01_analyses_full/rgids-",i,".RData"))
}

print("Done")
