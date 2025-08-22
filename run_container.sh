# podman source directory mapping needs an absolute
# path. So we wrap this up to ensure the user doesn't
# get confused
podman run -v `pwd`/output:/app/output -it soib "$@"
