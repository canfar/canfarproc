#!/bin/bash

apt update -y
apt dist-upgrade -y

# python3 by default for 18.04 and above
if [[ $(lsb_release -sr | sed -e 's|\.||') -ge 1804 ]]; then
    apt install python3-pip -y
else
    apt install python-pip -y
fi

# deps for cadc clients
apt install python-is-python3

curl -sL https://github.com/canfar/canfarproc/raw/master/worker/bin/canfar_update -o /usr/local/bin/canfar_update
chmod +x /usr/local/bin/canfar_update

canfar_update

# install batch
curl -sL https://github.com/canfar/canfarproc/raw/master/worker/bin/canfar_batch_prepare | bash

apt clean -y
