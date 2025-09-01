#!/bin/sh
#
# One time setup of compute node
#
# Install the bloatware called "azure CLI" (650 MB)
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Install podman
sudo apt install -y podman

# Install the container from konwn location in the NFS mount
xzcat /shared/container/`uname -m`/soib.tar.xz | podman load

# Proof that this node can shutdown itself!
az login --identity
