#!/bin/bash

# This script might turn into a Dockerfile some day

apt update -y
apt dist-upgrade -y
apt install python-pip

curl -sL https://github.com/canfar/canfarproc/raw/master/worker/bin/canfar_update -o /usr/local/bin/canfar_update
chmod +x /usr/local/bin/canfar_update

canfar_update

apt clean -y
