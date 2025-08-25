rm -rf soib-container
mkdir soib-container
mkdir soib-container/x86_64
mkdir soib-container/arm64
mkdir soib-container/output
cp output/config.R soib-container/output
cp run_container.sh soib-container/
cp README-CONTAINER.md soib-container/
cp install-x86_64-container.sh soib-container/
cp install-arm64-container.sh soib-container/

podman build --layers --squash-all -t soib .
# container in appropriate arch dir
podman save -o soib-container/`uname -m`/soib.tar localhost/soib:latest
rm soib-container.zip
zip -r soib-container.zip soib-container
