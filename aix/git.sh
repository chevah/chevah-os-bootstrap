#!/bin/sh
#
# Downloads, compiles and installs GIT as a regular user (eg. chevah).
# Adds the path to the git binary and other related env vars to its ~/.profile.
# Requires wget, gmake and sudo.
# Installs gcc, coreutils, zlib, zlib-devel RPMs from IBM's AIX Toolbox.
#

GIT_VERSION="1.9.0"
# Only selected versions would compile with the AIX Toolbox gcc compiler on AIX 5.3.
CURL_VERSION="7.19.7"

INSTALL_DIR="/usr/local"
CURL_CA_DIR="$INSTALL_DIR/etc/curl"
CURL_CA_FILE="$CURL_CA_DIR/cacert.pem"

GIT_DIR=git-${GIT_VERSION}
GIT_TAR_GZ=${GIT_DIR}.tar.gz
GIT_REMOTE_ARCHIVE=http://git-core.googlecode.com/files/${GIT_TAR_GZ}
CURL_DIR=curl-${CURL_VERSION}
CURL_TAR_GZ=${CURL_DIR}.tar.gz
CURL_REMOTE_ARCHIVE=http://ftp.sunet.se/pub/www/utilities/curl/${CURL_TAR_GZ}
CURL_CA_BUNDLE="http://curl.haxx.se/ca/cacert.pem"

# Get build deps from IBM's AIX Toolbox.
IBM_FTP_LINK_BASE="ftp://ftp.software.ibm.com/aix/freeSoftware/aixtoolbox/RPMS/ppc"
RPM_DEPS="gcc-4.2.0-3.aix5.3.ppc.rpm \
          coreutils-5.0-2.aix5.1.ppc.rpm \
          zlib-1.2.3-4.aix5.2.ppc.rpm \
          zlib-devel-1.2.3-4.aix5.2.ppc.rpm \
          "
# Absolute path to the install binary from the coreutils package.
INSTALL_SCRIPT="/usr/linux/bin/install"
LDFLAGS="-L${INSTALL_DIR}/lib -Wl,-blibpath:${INSTALL_DIR}/lib:/usr/lib:/lib"



#
# Here we go...
#

# Delete already existing RPM files and the git build directory.
echo "Removing already existing git-related files from the current directory..."
rm -rf $RPM_DEPS $GIT_TAR_GZ $GIT_DIR $CURL_TAR_GZ $CURL_DIR

# Download and install required RPMs.
for RPM_FILE in $RPM_DEPS; do
    echo "Downloading and installing ${RPM_FILE}..."
    RPM_DIR=`echo $RPM_FILE | cut -d\- -f1`
    wget "$IBM_FTP_LINK_BASE"/"$RPM_DIR"/"$RPM_FILE" \
        && sudo rpm -i $RPM_FILE \
        && rm $RPM_FILE
done

# Get and compile cURL, with custom CA bundle.
sudo mkdir -p $CURL_CA_DIR
wget $CURL_CA_BUNDLE -O curl_cacert.pem \
    && sudo $INSTALL_SCRIPT curl_cacert.pem $CURL_CA_FILE
wget $CURL_REMOTE_ARCHIVE \
    && gunzip -c $CURL_TAR_GZ | tar -xvf - \
    && cd $CURL_DIR \
    && ./configure --prefix="$INSTALL_DIR" --with-ca-bundle=${CURL_CA_FILE} \
    && gmake \
    && sudo make install

# Get and compile git.
export LDFLAGS
wget $GIT_REMOTE_ARCHIVE \
    && gunzip -c $GIT_TAR_GZ | tar -xvf - \
    && cd $GIT_DIR \
    && CURLDIR="$INSTALL_DIR" ./configure --prefix=${INSTALL_DIR} --without-tcltk \
    && gmake \
    && sudo gmake install INSTALL=${INSTALL_SCRIPT}

if [ -f ~/.profile ]; then
    echo 'alias git-init="git init --template='${INSTALL_DIR}'/share/git-core/templates"'\
        >> ~/.profile
    echo 'export GIT_EXEC_PATH='${INSTALL_DIR}'/libexec/git-core'\
        >> ~/.profile
    echo 'export PATH=$PATH:'${INSTALL_DIR}'/bin' >> ~/.profile
fi
