# Setup a specific number of max threads to run
# by defining them here.
# Default value is cores/2
# Note: these many threads may not be started if there
# is not enough RAM. This may happen if running under
# WSL, or a laptop with limited memory, etc
# On a Mac, set this to the number of performance cores
#threads <- 4

# Mask
# Defaults to whole country, i.e. "none"
cur_mask <- "none"

# my_assignment : Which subset to process
# if undefined, defaults to 1
#my_assignment <- 1:1

# You may choose to process a subset of species by
# defining those names here. An empty/absent list
# means "process all species"
species_to_process <- c(
#  "Coppersmith Barbet",
#  "Oriental Magpie-Robin",
#  "Rufous-throated Fulvetta" # Short runtime
)

# Runs RAM hungry jobs in interleaved fashion. This is
# the default.  Helps reduce peak memory pressure, making
# it easier to use on lower memory devices like laptops
# and Macs.
# If you set this to FALSE, peak memory usage will more or
# less happen early on, and then the memory usage will
# keep dropping.
#ram_interleave <- TRUE

# 3 GB margin to account for no process kills on Mac. Higher
# need for this if you set ram_interleave to FALSE
#ram_safety_margin <- 3000
