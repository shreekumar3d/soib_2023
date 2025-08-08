import pyreadr
from glob import glob
from pprint import pprint

results = []
for filename in glob('01_analyses_full/trends/stats/*.RData'):
    rdata = pyreadr.read_r(filename)
    run_stats = rdata['run_stats'].to_numpy()
    data_rows = int(run_stats[0,0])
    time = run_stats[0,1]
    max_ram = run_stats[0,2]
    pid = run_stats[0,3]
    results.append([data_rows, time, max_ram, pid, filename])

results.sort(key=lambda x:x[2])
pprint(results)
print("Number of species =",len(results))
