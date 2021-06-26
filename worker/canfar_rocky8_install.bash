#!/bin/bash

# This script might turn into a Dockerfile some day

# add EPEL repo for PIP
dnf install -y epel-release
dnf update -y

# minimal user love
dnf install -y bash-completion vim nano emacs-nox wget

# deps for vos and cadc stuff
dnf install -y python3-pip python3-devel python3-wheel openssl-devel rust cargo

# stuff for pip and users might like to have fortran...
dnf group install -y 'Development Tools'

curl -sL https://github.com/canfar/canfarproc/raw/master/worker/bin/canfar_update -o /usr/local/bin/canfar_update
chmod +x /usr/local/bin/canfar_update

# default rocky does not have /usr/local/bin in path when sudo'ing
sed -e '/Defaults/s|:/usr/bin|:/usr/local/bin:/usr/bin:|' -i /etc/sudoers

export PATH="/usr/local/bin:${PATH}"
canfar_update
canfar_batch_prepare

# cleanup
dnf clean all -y
