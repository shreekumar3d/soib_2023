rm -rf soib-container
mkdir soib-container
mkdir soib-container/x86_64
mkdir soib-container/output
cp output/config.R soib-container/output
cp run_container.sh soib-container/
cp README-CONTAINER.md soib-container/

podman build -t soib .
podman save -o soib-container/x86_64/soib.tar localhost/soib:latest
rm soib-container.zip
zip -r soib-container.zip soib-container
