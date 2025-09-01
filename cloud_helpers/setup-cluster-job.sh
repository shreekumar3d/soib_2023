#!/bin/bash
#
# Job setup script EXAMPLE
# Please customize this for your own environment
# This file is provided as a simple, fast to run example

# Required: Start from scratch
rm -rf shared

# Run the Uttarakhand mask using 2 nodes. All the nodes will
# run 4 threads.
#
# Assignment range of 1:10 will be split between these
# nodes (default)
#
# Job config will be stored in the config.R (default)
../py/bin/python3 setup-species-run.py \
	--mask Uttarakhand \
	--nodes 2 \
	--threads 4 \
	--assignment 6:15 \
	--arch x86_64

# It's possible to have more than 1 species run here, but that will be
# considered "advanced" usage
