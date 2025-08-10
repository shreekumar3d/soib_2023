# NOTES

## RAM Optimization

Due to the size of the datasets involved in SoIB, RAM is a large bottleneck.

### Baseline

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
$ ./perflog.py country_a1_p3s1.R

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

### RAM Optimization

The data table has lots of numerical fields.  All these are converted to integers.

Group ID and Observer IDs are carefully mapped to integer values.
Species names are converted to an integer backed by a lookup table
Timegroups are also converted to an integer backed by lookup table. This is
converted back to a string after load.
Observer count "X" is treated as 1

With alll this, data table RAM usage is 50% of earlier. Loads ~10x faster.

dataforanalyses had the data table, which was being deleted from memory just after
load.  dataforanalyses is thus separated into data and metadata parts.  Only the
metadata parts are loaded in run_species_trends

Peak RAM consumption reported for any species by R is now 3495 MB.  RSS values in
are in the 4-6 GB range.

These optimizations haven't changed the result.  Verified by checking that the
results (trends_1.csv) matches the reference values.

I feel R is still wasting memory somewhere - what else accounts for the difference
between peakMem and RSS reports from operating system ?

### RAM Optimization 2

singlespeciesrun() makes an expanded copy of data. This is not required when
we run glm. So delete it. This has a modest, but measurable impact on RAM usage.

Max Peak RAM consumption for any species is now slightly lower -  3226 MB.
RSS values are mostly between 4-5 GB, with many spikes to 6 GB.

The RSS doesn't reveal the entire picture. During runtime the memory consumption
seems to be mostly aroud 4-5 GB per process. At this point I could technically
squeeze 12 processes safely on my desktop (tests are still running at 6 procs)

### mcparallel for job launch

Code was using doParallel with sockets (PSOCK). Turns out that this keeps
copies of variables across worker threads. E.g. the "data" in the launch
process gets copied and an entire copy is kept in the RAM for every worked
thread. This is not the typical case with "copy on write", thus leading to
a lot of RAM usage. This also adds to extra time for launching processes,
etc, but that's minor compared to the RAM hit.

The way out of this is to use mcparallel to "fork" launch child processes.
This is applicable only for Linux. This avoids the data copy altogether,
adhering to "copy on write" semantics.  This is thus a very good method.
With this, the max peak RAM usage is down to 2919 MB - which is a significant
improvement.

The overall effect is seen in the RSS. A minimum of 44.6 GB RAM is free
(out of 64) in my test machine, when running with 6 procs. The worst case
RAM usage with 6 workers seems to be ~18 GB (excluding base OS overheads). 

The output of perf-trends.py reveals that workers have a wide variety of
RAM usage - 663 MB minimum to 2919 MB. Here are some interesting things:

1. 260 species consume less than 1 GB of RAM, with most having a runtime
   of much less than 30 seconds
2. 341 species consume 1-2GB, with most having a runtime under 1 minute
   Some of them even have a few second runtimes (surprise!)
3. Remaining 136 consume 2-3 GB. Runtimes vary, but are mostly over
   30 seconds, perhaps averaging around 80 seconds, with very few
   stretching close to 2 minutes

The program's output is cluttered with library loading messages, coming
from the workers. It is probably useful to load them all in the main script
before forking - may reduce some IO and some memory.

For the run with 6 workers, it took 2961 seconds.

Running many more threads hits at the limits of the system pretty quickly.
I was able to run 24 threads - but that took 2757 seconds. Useful, but not
a very big improvement - and certainly not representative of using 3x
more threads.

The sweet spot seemed to be at 16 (same as number of cores). The job finished
in 2472 seconds. Increasing parallelism to 18 jobs increased runtime to
2600 secs. The CPUs were idle. This is likely due to memory bandwidth or
other constraints
