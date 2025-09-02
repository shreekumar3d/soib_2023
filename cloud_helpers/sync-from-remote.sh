#!/bin/bash
echo "Syncing $1 to cluster_results directory"
mkdir cluster_results
echo "Sync: outputs"
rsync -avz $1:/shared/output/ cluster_results/output
echo "Sync: logs"
rsync -avz $1:/shared/logs/ cluster_results/logs
echo "Sync: config (for reference)"
rsync -avz $1:/shared/config/ cluster_results/config
