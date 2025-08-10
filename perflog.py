#!/usr/bin/env python3
# perflogger using procpath
#
# Tracks useful process and child process performance
# metrics, and creates a sqlite3 db file for
# later analysis
#
# Need procpath installed, and on PATH
# e.g. run the following before running:
# $ export PATH=$PATH:~/tools/py/bin
# $

import subprocess
import sys
from pprint import pprint
import time
import psutil

free_ram_max = psutil.virtual_memory().available
free_ram_min = free_ram_max

proc = subprocess.Popen(['Rscript',sys.argv[1]])
pid = proc.pid

outfile = f'{sys.argv[1]}-{pid}.db'
logproc = subprocess.Popen([
    'procpath',
    'record',
    '-i', '1',
    '--stop-without-result',
    '-d',
    outfile,
    f'$..children[?(@.stat.pid == {pid})]' # all processes
    ])
print(f'Tracing PID = {pid}')
try:
    while True:
        free_ram = psutil.virtual_memory().available
        free_ram_max = max(free_ram_max, free_ram)
        free_ram_min = min(free_ram_min, free_ram)
        try:
            proc.wait(1)
            break # if we come here the proc is done
        except subprocess.TimeoutExpired:
            pass
except:
    proc.kill()

# Perflog may not have exited, especially if ^C is pressed
# Wait a sec and kill
time.sleep(1)
logproc.kill()
logproc.wait()
print(f'Done tracing PID = {pid}')
print(f"Results db stored in:", outfile)
print(f"Free RAM max = {free_ram_max} min = {free_ram_min}")
