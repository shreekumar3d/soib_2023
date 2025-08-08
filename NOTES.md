# NOTES

## RAM Optimization

Due to the size of the datasets involved in SoIB, RAM is a large bottleneck.

The longest step is Part 3, Step 1, "Run species trends". Roughly takes around
an hour for a "assignment" (out of 1000) for the whole country on my desktop.
Config: AMD Ryzen 9 7950X (16 core, 32 thread). Plus 64 GB RAM.

I depend on randomgroupids supplied by Ashwin to match results.  For a minimal
test, randomgroupids.RData and dataforanalyses.RData need to be placed in
01_analyses_full.

After that, run

$ Rscript country_a1_p2s2.R

this generates data1.RData - which corresponds to the randomly sampled group
IDs, with my_assignment = 1

Next, run

$ export PATH=$PATH:~/tools/py/bin
$ export OMP_NUM_THREADS=1
$ ./perflog.py country_a1_p2s2.R

This will create a .db file (name printed on stdout), which has OS level
info on the performance of the parallel processes used to generate
trends_1.csv

Here, OMP_NUM_THREADS is set to 1 to avoid usage of multithreading inside
dependent libraries. This gives us a good estimate of relative CPU time
required across processing for various species.

procpath required for the next step is a python library. May be installed
using pip or venv.

Generate a graph to see the RAM usage, e.g.:

$ /tools/py/bin/procpath plot -d country_a1_p3s1.R-23373.db -q rss --relative-time -f rss.svg

and the CPU usage:

$ /tools/py/bin/procpath plot -d country_a1_p3s1.R-23373.db -q cpu --relative-time -f cpu.svg

Directory 01_analyses_full/trends/stats/ will also have an RData file
with stats of runs for each species.  This can be dumped using the
script trends-perf.py. The values in these files came from R's
peakMem library.  The least consumption for a species is about 1 GB RAM,
the max is close to 5 GB.

These values are surprisingly much lower than the RSS reported by the
linux kernel side - seen in rss.svg.  rss.svg shows values hovering around
5.5-8 GB for each of the 6 compute workers. top was used for monitoring,
the rss values are closer to those.  Clearly substantially more RAM is
being consumed somewhere in R - which needs to be track down and accounted
for.

For reference, data files and graphs are kept in opt-explanations directory
