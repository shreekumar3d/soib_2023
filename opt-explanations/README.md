
# Baseline (baseline)

Code changes : Added instrumentation on SoIB code

The following command:

$ ./perflog.py country_a1_p3s1.R

resulted in this file country_a1_p3s1.R-37442.db

Similarly named rss and cpu.svg files were generated using

~/tools/py/bin/procpath plot -d country_a1_p3s1.R-37442.db -q cpu --relative-time -f cpu.svg
~/tools/py/bin/procpath plot -d country_a1_p3s1.R-37442.db -q rss --relative-time -f rss.svg

stats-37442.tar.bz2 has the contents of 01_analyses_full/trends/stats/ after
running country_a1_p3s1.R. This has runtime stats of the job like
peak RAM consumption per species, PID (to correlate with db), total time,
and size of dataset (after the left join - see code)

# RAM optimizations (ramopt)

DB file, cpu.svg and rss.svg and stats.tar.gz are available.

# RAM optimization 2 (ramopt2)

DB file, cpu.svg and rss.svg and stats.tar.gz are available.

# mcparallel

DB file, cpu.svg and rss.svg and stats.tar.gz are available.
