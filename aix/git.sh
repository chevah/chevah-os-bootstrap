#!/bin/sh
#
# Downloads, compiles and installs GIT.
# Adds git path to ~/bash_profile path... if it exists.
# Requires wget, gmake and sudo.
# Installs gcc, zlib, zlib-devel and coreutils.
#

GIT_VERSION=1.9.0

# Folder where git will be installed.
INSTALL_FOLDER=~/.local

GIT_FOLDER=git-${GIT_VERSION}
GIT_TAR_GZ=${GIT_FOLDER}.tar.gz
GIT_REMOTE_ARCHIVE=http://git-core.googlecode.com/files/${GIT_TAR_GZ}

# Get build deps from AIX's toolbox.
IBM_FTP_LINK_BASE="ftp://ftp.software.ibm.com/aix/freeSoftware/aixtoolbox/RPMS/ppc"
RPM_DEPS="gcc-4.2.0-3.aix5.3.ppc.rpm \
          coreutils-5.0-2.aix5.1.ppc.rpm \
          zlib-1.2.3-4.aix5.2.ppc.rpm \
          zlib-devel-1.2.3-4.aix5.2.ppc.rpm"
for RPM_FILE in $RPM_DEPS; do
    RPM_DIR=`echo $RPM_FILE | cut -d\- -f1`
    wget "$IBM_FTP_LINK_BASE"/"$RPM_DIR"/"$RPM_FILE"
    sudo rpm -i $RPM_FILE && rm $RPM_FILE
done

# Absolute path to a ginstall from the coreutils package.
INSTALL_SCRIPT="/usr/linux/bin/install"

# Delete already existent git build folder and archive.
rm -rf $GIT_FOLDER $GIT_TAR_GZ

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
