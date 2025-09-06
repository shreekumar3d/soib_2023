#!/bin/sh
#
# One time setup of compute node
#

# Fail on errors
set -e

# Install the bloatware called "azure CLI" (650 MB)
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash || ( echo "Failed to install Azure CLI" ; exit 1 )

# Proof that this node can shutdown itself!
az login --identity || ( echo "Failed to manage this node. Have you run setup-node-rights.py ?" ; exit 1 )

# Install podman
sudo apt install -y podman || ( echo "Unable to install podman" ; exit 1 )

# Install the container from konwn location in the NFS mount
xzcat /shared/container/`uname -m`/soib.tar.xz | podman load || ( echo "Failed to load container" ; exit 1 )

echo "Node `hostname` is setup correctly"
