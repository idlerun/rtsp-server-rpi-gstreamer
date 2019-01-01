#!/bin/bash -e
cd $(dirname $0)

docker build -t build-gstreamer-raspi -f Dockerfile /opt/vc

# extract the built gstreamer
docker rm -f tmp &>/dev/null || true
docker create --user $(id -u):$(id -g) --name tmp build-gstreamer-raspi
rm -rf /opt/gstreamer
docker cp tmp:/opt/gstreamer /opt/gstreamer
docker rm -f tmp
