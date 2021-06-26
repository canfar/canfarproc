#!/bin/bash

# This script might turn into a Dockerfile some day

apt update -y
apt dist-upgrade -y

# python3 by default for 18.04 and above
if [[ $(lsb_release -sr | sed -e 's|\.||') -ge 1804 ]]; then
    apt install python3-pip -y
else
    apt install python-pip -y
fi

curl -sL https://github.com/canfar/canfarproc/raw/master/worker/bin/canfar_update -o /usr/local/bin/canfar_update
chmod +x /usr/local/bin/canfar_update

canfar_update
canfar_batch_prepare

apt clean -y
