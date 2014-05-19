#!/bin/sh
# Download, compile and install GIT
#
# Add git path to ~/bash_profile path... if it exists.
#
# Requires wget and sudo
#

GIT_VERSION=1.9.0

# Folder where git will be installed.
INSTALL_FOLDER=~/.local

GIT_FOLDER=git-${GIT_VERSION}
GIT_TAR_GZ=${GIT_FOLDER}.tar.gz
GIT_REMOTE_ARCHIVE=http://git-core.googlecode.com/files/${GIT_TAR_GZ}

# Absolute path to a ginstall compatible install file.
# We use a script that wraps ginstall arround aix install.
INSTALL_SCRIPT=$INSTALL_FOLDER/install.aix.sh
wget https://raw.githubusercontent.com/chevah/chevah-os-bootstrap/master/aix/install.aix.sh -O $INSTALL_SCRIPT
chmod +x $INSTALL_SCRIPT

# Get build deps
wget ftp://ftp.software.ibm.com/aix/freeSoftware/aixtoolbox/RPMS/ppc/gcc/gcc-4.2.0-3.aix5.3.ppc.rpm
sudo rpm -i gcc-4.2.0-3.aix5.3.ppc.rpm
wget ftp://ftp.software.ibm.com/aix/freeSoftware/aixtoolbox/RPMS/ppc/zlib/zlib-1.2.3-4.aix5.2.ppc.rpm
wget ftp://ftp.software.ibm.com/aix/freeSoftware/aixtoolbox/RPMS/ppc/zlib/zlib-devel-1.2.3-4.aix5.2.ppc.rpm
sudo rpm -i zlib-*.rpm

# Delete already existent git build folder and archive.
rm -rf $GIT_FOLDER
rm -rf $GIT_TAR_GZ

wget ${GIT_REMOTE_ARCHIVE}
gunzip -c $GIT_TAR_GZ | tar -xf -

cd $GIT_FOLDER

./configure --prefix=

NO_PYTHON=1 NO_CURL=1 NO_TCLTK=1 NO_GETTEXT=1 \
    gmake install\
        MSGFMT=echo\
        DESTDIR=${INSTALL_FOLDER} INSTALL=${INSTALL_SCRIPT}

if [ -f ~/.bash_profile ]; then
    echo 'alias git-init="git init --template='${INSTALL_FOLDER}'/share/git-core/templates"'\
        >> ~/.bash_profile
    echo 'export GIT_EXEC_PATH='${INSTALL_FOLDER}'/libexec/git-core'\
        >> ~/.bash_profile
    echo 'export PATH=$PATH:'${INSTALL_FOLDER}'/bin' >> ~/.bash_profile
fi
