# HOWTO run SoIB

This file basically jots down the exact steps I followed to run things
at this point in time. Note all the runtimes are with reference to
Shree's desktop - a 16 core AMD Ryzen 9 7950X with 64 GB RAM. Most
of the steps use 16 threads max. For XZ compression in one of the
steps, all cores are used.  GLM performance suffers with all cores
active, so this is the best configuraion for this particular machine.
Systems with higher memory bandwidth can run more threads.

## Start

After git clone, you need to copy two data files:

- ebd_IN_relJun-2024.txt
- ebd_sensitive_relJun-2024_IN.txt

This command copies the two txt files to the right place:

$ cp ~/biz/soib/data-packages/jul-30-ashwin/ebd_* 00_data/

For the next step to *not* fail, you need to up your stack limit:

$ ulimit -s unlimited

## Run Part 1, Step 1

$ time Rscript p1s1.R

There was 1 warning in `filter()`.
ℹ In argument: `|...`.
Caused by warning in `SAMPLING.EVENT.IDENTIFIER == c("S134340928", "S42696454", "S188588052",
    "S80680772", "S133479192", "S133022415", "S42127790", "S129418458",
    "S128838955", "S65035483", "S51110638")`:
! longer object length is not a multiple of shorter object length 
Reading and cleaning raw data: 1166.348 sec elapsed

real	19m30.464s
user	14m33.595s
sys	4m51.445s

Running this also overwrites these files which are under source control:

- 00_data/current_soib_migyears.RData
- 00_data/analyses_metadata.RData
- 00_data/spec_misid.RData

Next copy sensitive species map

$ cp ~/biz/soib/data-packages/jul-30-ashwin/Spatial\ files/maps_pa_sf.RData 00_data/

## Run Part 1, Step 2

$ time Rscript p1s2.R

adding map and grid variables to dataset: 334.793 sec elapsed

real	5m37.685s
user	5m25.653s
sys	0m11.869s

Note thas step Does not change any tracked files.

## Run Part 1, Step 3

Create symlink to fix paths:

    $ ln -s . data

Shree's changes reference files as "data/00_data" etc. So the symbolic link
is required.

    $ time Rscript p1s3.R

    Species list is already updated to latest taxonomy. Returning original list.
    Processing and filtering data for analyses: 631.324 sec elapsed

    real    10m34.294s
    user    9m33.472s
    sys	    1m0.329s

Running p1s3.R changes these files, which are all tracked under git:

- 01_analyses_full/fullspecieslist.csv
- 01_analyses_full/specieslists.RData
- 01_analyses_mask-ONEland/specieslists.RData
- 01_analyses_mask-PA/specieslists.RData
- 01_analyses_mask-cropland/specieslists.RData
- 01_analyses_mask-woodland/specieslists.RData
- 01_analyses_states/Andaman and Nicobar Islands/specieslists.RData
- 01_analyses_states/Andhra Pradesh/specieslists.RData
- 01_analyses_states/Arunachal Pradesh/specieslists.RData
- 01_analyses_states/Assam/specieslists.RData
- 01_analyses_states/Bihar/specieslists.RData
- 01_analyses_states/Chandigarh/specieslists.RData
- 01_analyses_states/Chhattisgarh/specieslists.RData
- 01_analyses_states/Dadra and Nagar Haveli/specieslists.RData
- 01_analyses_states/Daman and Diu/specieslists.RData
- 01_analyses_states/Delhi/specieslists.RData
- 01_analyses_states/Goa/specieslists.RData
- 01_analyses_states/Gujarat/specieslists.RData
- 01_analyses_states/Haryana/specieslists.RData
- 01_analyses_states/Himachal Pradesh/specieslists.RData
- 01_analyses_states/Jammu and Kashmir/specieslists.RData
- 01_analyses_states/Jharkhand/specieslists.RData
- 01_analyses_states/Karnataka/specieslists.RData
- 01_analyses_states/Kerala/specieslists.RData
- 01_analyses_states/Ladakh/specieslists.RData
- 01_analyses_states/Lakshadweep/specieslists.RData
- 01_analyses_states/Madhya Pradesh/specieslists.RData
- 01_analyses_states/Maharashtra/specieslists.RData
- 01_analyses_states/Manipur/specieslists.RData
- 01_analyses_states/Meghalaya/specieslists.RData
- 01_analyses_states/Mizoram/specieslists.RData
- 01_analyses_states/Nagaland/specieslists.RData
- 01_analyses_states/Odisha/specieslists.RData
- 01_analyses_states/Puducherry/specieslists.RData
- 01_analyses_states/Punjab/specieslists.RData
- 01_analyses_states/Rajasthan/specieslists.RData
- 01_analyses_states/Sikkim/specieslists.RData
- 01_analyses_states/Tamil Nadu/specieslists.RData
- 01_analyses_states/Telangana/specieslists.RData
- 01_analyses_states/Tripura/specieslists.RData
- 01_analyses_states/Uttar Pradesh/specieslists.RData
- 01_analyses_states/Uttarakhand/specieslists.RData
- 01_analyses_states/West Bengal/specieslists.RData

## Run Part 2, Step 1

Everything is ready to run the next step

    $ time Rscript p2s1.R

    ...
    generated random group IDs for all states: 142.96 sec elapsed

    real    7m38.232s
    user    7m17.255s
    sys	    0m20.684s

## Run Part 2, Step 2

Everything is ready to run the next step. Unlike the original
code, this does not generate remapped data. It merely optimizes
the data for each mask. Runtime uses the optimized data and
randomgroupids which are stored separately to get to the actual
data:

    $ time Rscript p2s2.R

    ...

    Generated subsampled data for Puducherry state: 1.182 sec elapsed
    Generated subsampled data for all states: 202.895 sec elapsed

    real    6m37.397s
    user    30m47.013s
    sys     0m27.133s

## Run Part 3, Step 1

Some prep is required to run this compute intensive step: species
trends calculations

    $ mkdir config/`hostname`
    $ cd config/`hostname`
    $ ln -s ../localhost/config.R config.R
    $ cd -
    $ mkdir output

With that done, ready to run.  By default the entire country is
run:

    $ export OMP_NUM_THREADS=1
    $ time Rscript p3s1.R
    ....
    Species trends for none: 1/1: 2392.163 sec elapsed
    Species trends for mask none (sims 1:1): 2401.14 sec elapsed

    real    40m3.312s
    user    579m59.924s
    sys     56m27.913s


First time runs don't dump info about script runtime estimates,
as it is not available. To fix it, generate the stats using:

$ ~/tools/py/bin/python3 gen-species-run-stats.py output/none/`hostname`/1/species/stats/ 01_analyses_full/

Note this has to be done for all regions separately.

Note different masks take different time to run:

e.g. Woodland

Species trends for woodland: 1/1: 421.973 sec elapsed
Species trends for mask woodland (sims 1:1): 426.586 sec elapsed

real	7m8.597s
user	104m11.083s
sys	7m33.916s

e.g. Kerala

Species trends for Kerala: 1/1: 192.011 sec elapsed
Species trends for mask Kerala (sims 1:1): 193.994 sec elapsed

real	3m15.934s
user	47m52.214s
sys	2m7.714s

e.g. Cropland

T=53.997 Threads:1 Done:78 Pending:0 Failed:0
Finished: Paddyfield Pipit Time taken:13.919 secs (100.00 %)
Species trends for cropland: 1/1: 50.274 sec elapsed
Species trends for mask cropland (sims 1:1): 52.918 sec elapsed

real	0m54.833s
user	11m19.864s
sys	1m0.883s

e.g. PA

T=140.246 Threads:1 Done:523 Pending:0 Failed:0
Finished: Nilgiri Pipit Time taken:1.28700000000001 secs (100.00 %)
Species trends for PA: 1/1: 138.056 sec elapsed
Species trends for mask PA (sims 1:1): 139.664 sec elapsed

real	2m21.588s
user	32m27.248s
sys	4m32.788s

e.g. ONEland

Finished: Green Avadavat Time taken:1.191 secs (100.00 %)
Species trends for ONEland: 1/1: 27.094 sec elapsed
Species trends for mask ONEland (sims 1:1): 28.597 sec elapsed

real	0m30.505s
user	6m9.547s
sys	0m50.357s

e.g. Karnataka

T=143.227 Threads:1 Done:238 Pending:0 Failed:0
Finished: Indian Vulture Time taken:8.125 secs (100.00 %)
Species trends for Karnataka: 1/1: 139.848 sec elapsed
Species trends for mask Karnataka (sims 1:1): 142.005 sec elapsed

real	2m23.938s
user	34m20.512s
sys	2m46.765s

e.g. Maharashtra

T=146.311 Threads:1 Done:280 Pending:0 Failed:0
Finished: White-bellied Blue Flycatcher Time taken:3.77800000000002 secs (100.00 %)
Species trends for Maharashtra: 1/1: 144.059 sec elapsed
Warning message:
There were 2 warnings in `mutate()`.
The first warning was:
ℹ In argument: `across(c("freq", "se"), ~as.numeric(.))`.
Caused by warning:
! NAs introduced by coercion
ℹ Run `dplyr::last_dplyr_warnings()` to see the 1 remaining warning. 
Species trends for mask Maharashtra (sims 1:1): 145.671 sec elapsed

real	2m27.599s
user	35m9.549s
sys	3m5.216s

e.g. Gujarat

T=62.528 Threads:1 Done:223 Pending:0 Failed:0
Finished: Striolated Bunting Time taken:1.642 secs (100.00 %)
Species trends for Gujarat: 1/1: 60.375 sec elapsed
Species trends for mask Gujarat (sims 1:1): 61.216 sec elapsed

real	1m3.140s
user	14m16.985s
sys	1m41.948s

Telangana

T=5.529 Threads:1 Done:19 Pending:0 Failed:0
Finished: Tricolored Munia Time taken:1.32 secs (100.00 %)
Species trends for Telangana: 1/1: 3.403 sec elapsed
Species trends for mask Telangana (sims 1:1): 3.806 sec elapsed

real	0m5.703s
user	0m33.288s
sys	0m5.890s

Uttarakhand

T=23.046 Threads:1 Done:103 Pending:0 Failed:0
Finished: Red-headed Bullfinch Time taken:2.059 secs (100.00 %)
Species trends for Uttarakhand: 1/1: 20.642 sec elapsed
Species trends for mask Uttarakhand (sims 1:1): 21.641 sec elapsed

real	0m23.540s
user	4m41.073s
sys	0m38.752s

# Dataset sizes for various region masks

Sizes of datasets vary quite a bit. They are captured here for reference:

157M Aug 31 09:08 ./01_analyses_full/dataforanalyses.RData-data_opt
 31M Aug 31 09:09 ./01_analyses_mask-cropland/dataforanalyses.RData-data_opt
 15M Aug 31 09:10 ./01_analyses_mask-ONEland/dataforanalyses.RData-data_opt
 17M Aug 31 09:10 ./01_analyses_mask-PA/dataforanalyses.RData-data_opt
 68M Aug 31 09:09 ./01_analyses_mask-woodland/dataforanalyses.RData-data_opt
4.1M Aug 31 09:12 ./01_analyses_states/Assam/dataforanalyses.RData-data_opt
168K Aug 31 09:10 ./01_analyses_states/Chandigarh/dataforanalyses.RData-data_opt
2.3M Aug 31 09:12 ./01_analyses_states/Chhattisgarh/dataforanalyses.RData-data_opt
1.9M Aug 31 09:12 ./01_analyses_states/Delhi/dataforanalyses.RData-data_opt
3.1M Aug 31 09:10 ./01_analyses_states/Goa/dataforanalyses.RData-data_opt
8.5M Aug 31 09:11 ./01_analyses_states/Gujarat/dataforanalyses.RData-data_opt
2.5M Aug 31 09:11 ./01_analyses_states/Haryana/dataforanalyses.RData-data_opt
 29M Aug 31 09:11 ./01_analyses_states/Karnataka/dataforanalyses.RData-data_opt
 23M Aug 31 09:13 ./01_analyses_states/Kerala/dataforanalyses.RData-data_opt
679K Aug 31 09:13 ./01_analyses_states/Ladakh/dataforanalyses.RData-data_opt
 19M Aug 31 09:13 ./01_analyses_states/Maharashtra/dataforanalyses.RData-data_opt
291K Aug 31 09:13 ./01_analyses_states/Meghalaya/dataforanalyses.RData-data_opt
163K Aug 31 09:12 ./01_analyses_states/Nagaland/dataforanalyses.RData-data_opt
1.5M Aug 31 09:10 ./01_analyses_states/Odisha/dataforanalyses.RData-data_opt
429K Aug 31 09:13 ./01_analyses_states/Puducherry/dataforanalyses.RData-data_opt
903K Aug 31 09:12 ./01_analyses_states/Punjab/dataforanalyses.RData-data_opt
5.8M Aug 31 09:11 ./01_analyses_states/Rajasthan/dataforanalyses.RData-data_opt
554K Aug 31 09:11 ./01_analyses_states/Sikkim/dataforanalyses.RData-data_opt
2.6M Aug 31 09:12 ./01_analyses_states/Telangana/dataforanalyses.RData-data_opt
435K Aug 31 09:12 ./01_analyses_states/Tripura/dataforanalyses.RData-data_opt
8.6M Aug 31 09:11 ./01_analyses_states/Uttarakhand/dataforanalyses.RData-data_opt

