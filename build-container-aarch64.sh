podman build --layers --squash-all -t soib .
rm -rf aarch64
mkdir aarch64
podman save -o aarch64/soib.tar localhost/soib:latest

