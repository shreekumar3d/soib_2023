podman build --layers --squash-all -t soib .
rm -rf x86_64
mkdir x86_64
podman save -o x86_64/soib.tar localhost/soib:latest

