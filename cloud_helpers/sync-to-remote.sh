#!/bin/bash
echo "Syncing shared directory to $1"
rsync --progress -avz shared/ $1:/shared/
