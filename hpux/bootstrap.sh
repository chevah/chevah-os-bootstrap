#!/usr/bin/sh
# Simple script for creating a usable HPUX system
# from an CLOE system.
#
# On HPUX do:
#
# login as root
# TERM=xterm
# export TERM
# vi bootstrap.sh
#
# and paste the content of this file, save and exit.
# Then run:
#
# sh bootstrap.sh
#
# After bash is installed, you can manually update /etc/passwd
# to use bash as the default shell.
#
# For `root` account keep shell as '/bin/sh' and root in '/'

PATH=${PATH}:/usr/local/sbin:/usr/local/bin
export PATH

NEWUSER='chevah'
WORK_FOLDER='/bootstrap'
DEPOTHELPER_DEPOT='depothelper-2.00-ia64-11.31.depot'
DEPOTHELPER_DEPOT_GZ=${DEPOTHELPER_DEPOT}.gz

start_folder=`pwd`

cat > ~/.netrc <<DELIM
machine hpux.connect.org.uk
    login anonymous
    password test@test.ro

macdef bootstrap
    cd hpux/Sysadmin/depothelper-2.00/
    bin
    get $DEPOTHELPER_DEPOT_GZ
    quit

DELIM

chmod 700 ~/.netrc

mkdir -p $WORK_FOLDER
cd $WORK_FOLDER

echo 'After the FTP session starts, wait for FTP prompt and then type:'
echo '"$ bootstrap"  (include the dolar sign)'
echo 'The script will take care of the rest.'
echo ''
echo 'Is time to type the magic text.'
ftp hpux.connect.org.uk

# Let's continue after we have the download.

gunzip ${DEPOTHELPER_DEPOT_GZ}
swinstall -s ${WORK_FOLDER}/${DEPOTHELPER_DEPOT} depothelper

echo 'Download might be slow... be patient'

depothelper bash
# Linking bash as many scripts are hardcoded to #!/bin/bash and
# env is not working on HPUX.
ln -s /usr/local/bin/bash /bin/bash

depothelper wget
depothelper make
depothelper git
depothelper sudo
depothelper patch
depothelper rsync
depothelper less

# Resize home partition.
umount /dev/vg00/rlvol5
lvextend -L 102400 /dev/vg00/lvol5
extendfs -F vxfs /dev/vg00/rlvol5
mount /dev/vg00/rlvol5

echo 'Now you will have to change password for' ${NEWUSER}
echo 'and set /usr/local/bin/bash as the default shell.'

echo ''

cp /usr/local/etc/sudoers.sample /usr/local/etc/sudoers
echo '%adm        ALL=(ALL) NOPASSWD: ALL' >> /usr/local/etc/sudoers
chown root:root /usr/local/etc/sudoers
chmod 440 /usr/local/etc/sudoers

# Add default files for root.
cat > ~/.bash_profile <<DELIM
export PATH=${PATH}:/usr/sbin:/usr/local/sbin:/usr/local/bin
export TERM=vt200

DELIM


# Add default files for new user.
useradd -G adm $NEWUSER
mkdir /home/${NEWUSER}/.ssh
cp -r ~/.ssh/authorized_keys /home/${NEWUSER}/.ssh/

cat > /home/${NEWUSER}/.bash_profile <<DELIM
export PATH=${PATH}:/usr/sbin:/usr/local/sbin:/usr/local/bin
export TERM=vt200
alias paver=~paver.sh
export GIT_SSL_NO_VERIFY=true

DELIM

chown -R ${NEWUSER} /home/${NEWUSER}

cd $start_folder
