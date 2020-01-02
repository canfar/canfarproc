#!/bin/bash

# This script might turn into a Dockerfile some day

# add EPEL repo for PIP
yum install -y epel-release
yum update -y

# bash love
yum install -y bash-completion

# deps for vos and cadc stuff
yum install -y python36-pip python36-devel fuse-libs idna python-args openssl-devel

# stuff for pip and users might like to have fortran...
yum groupinstall -y 'Development Tools'

curl -sL https://github.com/canfar/canfarproc/raw/master/worker/bin/canfar_update -o /usr/local/bin/canfar_update
chmod +x /usr/local/bin/canfar_update

# default centos does not have /usr/local/bin in path when sudo'ing
sed -e '/Defaults/s|:/usr/bin|:/usr/local/bin:/usr/bin:|' -i /etc/sudoers

export PATH="/usr/local/bin:${PATH}"
canfar_update

# cleanup
yum clean all -y
