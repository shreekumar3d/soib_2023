#!/bin/sh

set -e

# Packages we need
sudo apt update && sudo apt install -y python3-inotify || ( echo "Unable to install python3-inotify" ; exit 1 )
