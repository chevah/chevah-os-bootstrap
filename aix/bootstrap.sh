#!/bin/sh
#
# Simple script for creating a usable AIX system from a minimal AIX install.
#
# Login as root and create the bootstrap script with
#
#    vi bootstrap.sh
#
# and then paste the content of this file, save and exit.
# Then run:
#
#    sh bootstrap.sh
#
# In the FTP session, type "$ bootstrap", including the dollar sign.

NEW_USER="chevah"
WORK_FOLDER='/bootstrap'
START_FOLDER=`pwd`

WGET_RPM_FILE="wget-1.9.1-1.aix5.1.ppc.rpm"
IBM_FTP_SERVER="ftp.software.ibm.com"
IBM_FTP_BASEDIR="aix/freeSoftware/aixtoolbox/RPMS/ppc"
IBM_FTP_LINK_BASE="${IBM_FTP_SERVER}/${IBM_FTP_BASEDIR}"
RPM_DEPS="bash-3.2-1.aix5.2.ppc.rpm \
    vim-common-6.3-1.aix5.1.ppc.rpm \
    vim-enhanced-6.3-1.aix5.1.ppc.rpm \
    make-3.80-1.aix5.1.ppc.rpm \
    sudo-1.6.9p23-2noldap.aix5.3.ppc.rpm \
    "



#
# Here we go...
#

cat > ~/.netrc <<DELIM
machine $IBM_FTP_SERVER
        login anonymous
        password user@example.com

macdef bootstrap
        cd ${IBM_FTP_BASEDIR}/wget/
        bin
        get $WGET_RPM_FILE
        quit

DELIM

chmod 700 ~/.netrc

mkdir -p $WORK_FOLDER \
    && cd $WORK_FOLDER

echo ''
echo 'The FTP session will start. Wait for the prompt and then type the command'
echo 'below, including the dollar sign. The script will take care of the rest.'
echo ''
echo '$ bootstrap'
echo ''

ftp $IBM_FTP_SERVER

# We install wget first so that we can use it in the script.
rpm -i $WGET_RPM_FILE \
    && rm $WGET_RPM_FILE

# Get the other required rpms from AIX's toolbox.
for RPM_FILE in $RPM_DEPS; do
    echo "Downloading and installing ${RPM_FILE}..."
    RPM_DIR=`echo $RPM_FILE | cut -d\- -f1`
    wget "$IBM_FTP_LINK_BASE"/"$RPM_DIR"/"$RPM_FILE" \
        && rpm -i $RPM_FILE \
        && rm $RPM_FILE
done

echo '%staff        ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers \
    && chmod 440 /etc/sudoers

# Create the new user.
useradd -m ${NEW_USER}

# Write some default values in the .profile file.
cat >> /home/${NEW_USER}/.profile <<DELIM

alias paver=./paver.sh
export TERM=xterm
alias ge=vi

DELIM

cd $START_FOLDER
rmdir $WORK_FOLDER

