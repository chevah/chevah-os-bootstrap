#!/usr/bin/sh
# Simple script for creating a usable AIX system
# from a standard VLP system or a basic AIX install.
#
# On AIX do:
#
# su
# vi bootstrap.sh
#
# and paste the content of this file, save and exit.
# Then run:
#
# sh bootstrap.sh
#
# In the FTP session, type "$ bootstrap", including the dollar sign.
#
# After bash is installed, you can manually update /etc/passwd
# to use bash as the default shell.

NEW_USER="chevah"
WORK_FOLDER='/bootstrap'

start_folder=`pwd`

PATH=${PATH}:/usr/local/sbin:/usr/local/bin
export PATH

cat > ~/.netrc <<DELIM
machine ftp.software.ibm.com
        login anonymous
        password test@test.ro

macdef bootstrap
        cd aix/freeSoftware/aixtoolbox/RPMS/ppc/wget/
        bin
        get wget-1.9.1-1.aix5.1.ppc.rpm
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

ftp ftp.software.ibm.com

# We install wget first so that we can use it in the script.
rpm -i wget-1.9.1-1.aix5.1.ppc.rpm


# Get the other required rpms from AIX's toolbox.
IBM_FTP_LINK_BASE="ftp://ftp.software.ibm.com/aix/freeSoftware/aixtoolbox/RPMS/ppc"
RPM_DEPS="bash-3.2-1.aix5.2.ppc.rpm \
    vim-common-6.3-1.aix5.1.ppc.rpm \
    vim-enhanced-6.3-1.aix5.1.ppc.rpm \
    make-3.80-1.aix5.1.ppc.rpm"
for RPM_FILE in $RPM_DEPS; do
    RPM_DIR=`echo $RPM_FILE | cut -d\- -f1`
    wget "$IBM_FTP_LINK_BASE"/"$RPM_DIR"/"$RPM_FILE"
    sudo rpm -i $RPM_FILE && rm $RPM_FILE
done

# We need sudo -E, thus a newer sudo than the one in the AIX toolbox.
SUDO_RPM=sudo-1.8.10-4.aix53.pam.rpm
wget ftp://ftp.sudo.ws/pub/sudo/packages/AIX/5.3/$SUDO_RPM
rpm -i $SUDO_RPM

echo '%staff        ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers
chmod 440 /etc/sudoers

# Create user
useradd -m ${NEW_USER}

# Write some default values in the .profile file.
cat >> /home/${NEW_USER}/.profile <<DELIM

alias paver=./paver.sh
export TERM=xterm
alias ge=vi
export GIT_EXEC_PATH=~/.local/libexec/git-core
export PATH=$PATH:~/.local/bin

DELIM

chown -R ${NEW_USER} /home/${NEW_USER}
chgrp -R staff /home/${NEW_USER}
