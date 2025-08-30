podman build --layers --squash-all -t soib .
rm -rf arm64
mkdir arm64
podman save -o arm64/soib.tar localhost/soib:latest

