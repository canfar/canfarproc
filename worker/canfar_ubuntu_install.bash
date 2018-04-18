##!/bin/bash

# This script might turn into a Dockerfile some day

apt update -y
apt dist-upgrade -y

# deps for vos stuff
apt install python-pip
pip install vos vofs cadcdata

curl -sL https://github.com/canfar/canfarproc/raw/master/worker/bin/canfar_update -o /usr/local/bin/canfar_update
chmod +x /usr/local/bin/canfar_update

canfar_update

# cleanup
apt clean -y
