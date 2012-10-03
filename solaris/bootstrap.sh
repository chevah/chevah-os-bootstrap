#!/usr/bin/sh
# Simple script for creating a usable Solaris system
# from an base install.
# 

PATH=${PATH}:/opt/csw/bin
export PATH

NEWUSER='adi'
WORK_FOLDER='/bootstrap'

start_folder=`pwd`

mkdir -p $WORK_FOLDER
cd $WORK_FOLDER

# Install pkgutil
pkgadd -d http://get.opencsw.org/now

pkgutil -U
pkgutil -y -i bash sudo openssh openssh_client git
h
useradd -g adm -m\
    -d /export/home/${NEWUSER}\
    -s /opt/csw/bin/bash\
    $NEWUSER
echo \
    'export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/ccs/bin:/usr/sfw/bin:/opt/csw/bin:/opt/csw/sbin' \
    /export/home/${NEWUSER}/.bash_profile> 

chown -R ${NEWUSER} /export/home/${NEWUSER}


# Fix sudoers file.
echo '%adm        ALL=(ALL) NOPASSWD: ALL' >> /etc/opt/csw/sudoers
chown root:root /etc/opt/csw/sudoers


# Fix DNS resolver.
echo "nameserver 8.8.8.8" > /etc/resolv.conf
echo "nameserver 8.8.4.4" >> /etc/resolv.conf

cp /etc/nsswitch.conf /etc/nsswitch.conf.chevah
sed "s/^hosts:.*/hosts:      files dns/"\
    /etc/nsswitch.conf.chevah > /etc/nsswitch.conf
