import subprocess
import sys
from pprint import pprint
import time
import psutil

free_ram_max = psutil.virtual_memory().available
free_ram_min = free_ram_max

proc = subprocess.Popen(
    ["Rscript"]+sys.argv[1:], stdout=subprocess.PIPE, stderr=subprocess.STDOUT
)

pid = proc.pid
perflog = f'{sys.argv[1]}-{pid}.db'
# Ensure procpath is on PATH
logproc = subprocess.Popen([
    'procpath',
    'record',
    '-i', '1',
    '--stop-without-result',
    '-d',
    perflog,
    f'$..children[?(@.stat.pid == {pid})]' # all processes
    ])

stdlog_name = f'{sys.argv[1]}-{pid}-log'
stdlog = open(stdlog_name, 'wb')

try:
    while True:
        free_ram = psutil.virtual_memory().available
        free_ram_max = max(free_ram_max, free_ram)
        free_ram_min = min(free_ram_min, free_ram)
        line = proc.stdout.readline()
        if len(line)==0:
            break
        sys.stdout.buffer.write(line)
        stdlog.write(line)
except:
    print("Stopping due to ^C...")
    proc.kill()

print("Waiting for proc to die...")
proc.wait()

time.sleep(1)
logproc.kill()
logproc.wait()

stdlog.close()

print(f'Done tracing PID = {pid}')
print(f"Results db stored in: {perflog}")
print(f"Output Log: {stdlog_name}")
print(f"Free RAM max = {free_ram_max} min = {free_ram_min} max_used = {free_ram_max-free_ram_min}")
