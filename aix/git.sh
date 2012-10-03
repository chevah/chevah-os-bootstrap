#!/bin/sh
# Download, compile and install GIT
#
# Add git path to ~/bash_profile path... if it exists.
#
# Requires wget and a compiler
#

GIT_VERSION=1.7.10

# Folder where git will be installed.
INSTALL_FOLDER=~/.local

GIT_FOLDER=git-${GIT_VERSION}
GIT_TAR=${GIT_FOLDER}.tar
GIT_TAR_GZ=${GIT_TAR}.gz
GIT_REMOTE_ARCHIVE=http://git-core.googlecode.com/files/${GIT_TAR_GZ}

# Absolute path to a ginstall compatible install file.
# We use a script that wraps ginstall arround aix install.
INSTALL_SCRIPT=~/chevah/deps/src/chevah-bootstrap/aix/install.aix.sh

# Delete already existent git build folder and archive.
rm -rf $GIT_FOLDER
rm -rf $GIT_TAR

wget ${GIT_REMOTE_ARCHIVE}
gunzip $GIT_TAR_GZ
tar -xf $GIT_TAR

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
