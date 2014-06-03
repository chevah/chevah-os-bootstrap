#!/bin/sh
#
# Downloads, compiles and installs GIT as a regular user (eg. chevah).
# Adds the path to the git binary and other related env vars to its ~/.profile.
# Requires wget, gmake and sudo.
# Installs gcc, coreutils, zlib, zlib-devel RPMs from IBM.
#

GIT_VERSION=1.9.0

INSTALL_FOLDER="/usr/local"

GIT_FOLDER=git-${GIT_VERSION}
GIT_TAR_GZ=${GIT_FOLDER}.tar.gz
GIT_REMOTE_ARCHIVE=http://git-core.googlecode.com/files/${GIT_TAR_GZ}

# Get build deps from AIX's toolbox.
IBM_FTP_LINK_BASE="ftp://ftp.software.ibm.com/aix/freeSoftware/aixtoolbox/RPMS/ppc"
RPM_DEPS="gcc-4.2.0-3.aix5.3.ppc.rpm \
          coreutils-5.0-2.aix5.1.ppc.rpm \
          zlib-1.2.3-4.aix5.2.ppc.rpm \
          zlib-devel-1.2.3-4.aix5.2.ppc.rpm \
          "
# Absolute path to the install binary from the coreutils package.
INSTALL_SCRIPT="/usr/linux/bin/install"

#
# Here we go...
#

# Delete already existing RPM files and the git build directory.
echo "Removing already existing git-related files from the current directory..."
rm -rf $RPM_DEPS $GIT_TAR_GZ $GIT_FOLDER

for RPM_FILE in $RPM_DEPS; do
    echo "Downloading and installing ${RPM_FILE}..."
    RPM_DIR=`echo $RPM_FILE | cut -d\- -f1`
    wget "$IBM_FTP_LINK_BASE"/"$RPM_DIR"/"$RPM_FILE"
    sudo rpm -i $RPM_FILE && rm $RPM_FILE
done

wget ${GIT_REMOTE_ARCHIVE}
gunzip -c $GIT_TAR_GZ | tar -xvf -

cd $GIT_FOLDER

./configure --prefix=${INSTALL_FOLDER} --without-tcltk \
    && MSGFMT=echo gmake \
    && MSGFMT=echo sudo gmake install INSTALL=${INSTALL_SCRIPT}

if [ -f ~/.profile ]; then
    echo 'alias git-init="git init --template='${INSTALL_FOLDER}'/share/git-core/templates"'\
        >> ~/.profile
    echo 'export GIT_EXEC_PATH='${INSTALL_FOLDER}'/libexec/git-core'\
        >> ~/.profile
    echo 'export PATH=$PATH:'${INSTALL_FOLDER}'/bin' >> ~/.profile
fi
