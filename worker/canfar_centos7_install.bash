#!/bin/bash

# This script might turn into a Dockerfile some day

# bash love
yum install -y bash-completion

# add EPEL repo for PIP
yum install -y epel-release
yum update -y
# deps for vos and cadc stuff
yum install -y python36-pip fuse-libs idna python-args

curl -sL https://github.com/canfar/canfarproc/raw/master/worker/bin/canfar_update -o /usr/local/bin/canfar_update
chmod +x /usr/local/bin/canfar_update

# default centos does not have /usr/local/bin in path when sudo'ing
sed -e '/Defaults/s|:/usr/bin|:/usr/local/bin:/usr/bin:|' -i /etc/sudoers

canfar_update

# cleanup
yum clean all -y
