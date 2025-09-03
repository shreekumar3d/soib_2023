#
# ed was computed earlier using expand_dt
# with the newer method the resultant ed is somewhat
# different
# this captures the differences
#
library(dplyr)
load("ed-new.RData") # new approach, as ed
load("ed-prev.RData") # based on expand_dt, as ed1

only_in_new_ed <- anti_join(ed, ed1, by=c("gridg1","gridg3","no.sp","month","timegroups","OBSERVATION.COUNT"))
message("saving only_in_new_ed.csv")
write.csv(only_in_new_ed, "only_in_new_ed.csv")

# harder to compare as no "context" in old ed
#only_in_old_ed <- anti_join(ed1, ed, by=c("gridg1","gridg3","no.sp","month","timegroups","OBSERVATION.COUNT"))
#message("saving only_in_old_ed.csv")
#write.csv(only_in_old_ed, "only_in_old_ed.csv")
