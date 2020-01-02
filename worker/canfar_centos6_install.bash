#!/bin/bash

# This script might turn into a Dockerfile some day

# add EPEL repo for PIP
yum install -y epel-release

yum update -y

# bash love
yum install -y bash-completion

# install ius repo for python-2.7
curl -Ls https://setup.ius.io | sudo bash

# deps for vos and cadc stuff
yum install python27-pip fuse fuse-libs

curl -sL https://github.com/canfar/canfarproc/raw/master/worker/bin/canfar_update -o /usr/local/bin/canfar_update
chmod +x /usr/local/bin/canfar_update

# default centos does not have /usr/local/bin in path when sudo'ing
sed -e '/Defaults/s|:/usr/bin|:/usr/local/bin:/usr/bin:|' -i /etc/sudoers

# vofs stuff
usermod -a -G fuse centos

export PATH="/usr/local/bin:${PATH}"
canfar_update

yum clean all -y
