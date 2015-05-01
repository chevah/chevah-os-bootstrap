#!/bin/sh
#
# Downloads, compiles and installs cURL & Git as a user with SUDO rights in AIX.
# Requires wget, gmake, sudo and (optionally) OpenSSL.
# It makes use of IBM's XL C compiler, if found. Otherwise, it downloads IBM's
# GCC RPMs: libgcc and gcc.
# It also downloads and install the IBM RPMs for coreutils, zlib and zlib-devel.
# Adds the path to the git binary and other related env vars to its ~/.profile.
#

INSTALL_DIR="/usr/local"
CURL_CA_DIR="$INSTALL_DIR/etc/curl"
CURL_CA_FILE="$CURL_CA_DIR/cacert.pem"

# IBM's AIX Toolbox FTP base location.
IBM_LINK_BASE="ftp://ftp.software.ibm.com/aix/freeSoftware/aixtoolbox/RPMS/ppc"
RPM_DEPS="
    coreutils-5.0-2.aix5.1.ppc.rpm \
    zlib-1.2.3-4.aix5.2.ppc.rpm \
    zlib-devel-1.2.3-4.aix5.2.ppc.rpm \
    "

# Crude test to look for the IBM's compiler.
/usr/vac/bin/xlc_r -qversion >/dev/null 2>&1
if [ $? = 0 ]; then
    export PATH="/usr/vac/bin:${PATH}"
    export CC="xlc_r"
    CURL_VERSION="7.42.1"
    GIT_VERSION="2.3.7"
else
    # Couldn't find IBM's XL C compiler, will install and use IBM GCC..."
    # Beware: Only selected cURL versions compile with the GCC from IBM Toolbox.
    export CC="gcc"
    CURL_VERSION="7.19.7"
    GIT_VERSION="2.3.7"
    RPM_DEPS="$RPM_DEPS \
        gcc-4.2.0-3.aix5.3.ppc.rpm \
        libgcc-4.2.0-3.aix5.3.ppc.rpm \
        "
fi

CURL_DIR=curl-${CURL_VERSION}
CURL_TAR_GZ=${CURL_DIR}.tar.gz
CURL_REMOTE_ARCHIVE=http://ftp.sunet.se/pub/www/utilities/curl/${CURL_TAR_GZ}
CURL_CA_BUNDLE="http://curl.haxx.se/ca/cacert.pem"
GIT_DIR=git-${GIT_VERSION}
GIT_TAR_GZ=${GIT_DIR}.tar.gz
GIT_REMOTE_ARCHIVE=https://www.kernel.org/pub/software/scm/git/${GIT_TAR_GZ}

# Absolute path to the "install" binary from the coreutils package.
INSTALL_SCRIPT="/usr/linux/bin/install"
LDFLAGS="-L${INSTALL_DIR}/lib -Wl,-blibpath:${INSTALL_DIR}/lib:/usr/lib:/lib"
CPPFLAGS="${CPPFLAGS} -I$INSTALL_DIR/include/"
START_FOLDER=`pwd`


# Outputs the basename of the RPM when given the complete name of the RPM file.
get_rpm_name() {
    local rpm_file_name=$1

    echo $rpm_file_name | grep 'devel-' >/dev/null
    if [ $? = 0 ]; then
        digit_to_cut=2
    else
        digit_to_cut=1
    fi
    echo $rpm_file_name | cut -d '-' -f 1-${digit_to_cut}
}

# Check existing free space in target partition against required free space.
extend_partition_as_needed() {
    local partition_name=$1
    local mb_of_required_space=$2

    echo "Free space needed on the ${partition_name} partition: \c"
    echo "${mb_of_required_space} MB"
    df -m | grep ${partition_name} >/dev/null 2>&1
    if [ $? != 0 ]; then
        echo "No ${partition_name} partition found. \c"
        echo "Checking the root partition..."
        partition_name='/'
    else
        echo "Checking the ${partition_name} partition..."
    fi
    mb_of_free_space=`df -m | grep ${partition_name} | head -n 1 \
            | awk '{print $3}' | cut -d\. -f 1`
    if [[ ${mb_of_free_space} -lt ${mb_of_required_space} ]]; then
        mb_of_more_space=`echo ${mb_of_required_space}-${mb_of_free_space} | bc`
        echo "Insufficient free space on partition ${partition_name}!"
        echo "Extending ${partition_name} with ${mb_of_more_space} MB..."
        sudo chfs -a size=+${mb_of_more_space}M ${partition_name}
    else
        echo "There seems to be sufficient space on ${partition_name}: \c"
        echo "${mb_of_free_space} MB."
    fi
}


#
# Here we go...
#

for RPM_FILE in $RPM_DEPS; do
    RPM_BASENAME=`get_rpm_name ${RPM_FILE}`
    RPM_DEPS_BASENAMES="${RPM_DEPS_BASENAMES} $RPM_BASENAME"
done

echo "\nThis script downloads and installs cURL and Git in AIX 5.3 or newer."
echo "Requires wget, gmake, sudo and (optionally) OpenSSL headers and libs."
echo "Uses IBM XL C compiler (if found) or IBM's GCC from the Toolbox RPMs."
echo "Installs RPM deps from IBM's Toolbox and extends partitions as needed."
echo "Check below for specific details.\n"
echo "Install directory:    ${INSTALL_DIR}"
echo "Compiler to use:      ${CC}"
echo "RPMs needed:         ${RPM_DEPS_BASENAMES}\n"

# Delete already existing files and the git build directory.
echo "Removing files left over by this script in the current dir, if any...\n"
rm -rf $GIT_TAR_GZ $GIT_DIR $CURL_TAR_GZ $CURL_DIR

extend_partition_as_needed /opt 150
extend_partition_as_needed /usr 100

# Download and install required RPMs.
echo "\nChecking and installing RPMs as needed:"
for RPM_FILE in $RPM_DEPS; do
    RPM_NAME=`get_rpm_name ${RPM_FILE}`
    echo "Checking if ${RPM_NAME} is already installed..."
    RPM_INSTALLED=`rpm -qa | grep ^"${RPM_NAME}-[0-9]"`
    if [ $? = 0 ]; then
        echo "${RPM_NAME} RPM already installed: ${RPM_INSTALLED}."
    else
        echo "Downloading and installing ${RPM_FILE}..."
        RPM_DIR=`echo $RPM_FILE | cut -d\- -f1`
        if [ $RPM_DIR = "libgcc" ]; then
            RPM_DIR="gcc"
        fi
        wget --quiet "$IBM_LINK_BASE"/"$RPM_DIR"/"$RPM_FILE" \
            && sudo rpm -i $RPM_FILE \
            && rm $RPM_FILE
        if [ $? != 0 ]; then
            echo "\nCouldn't make sure the ${RPM_NAME} RPM is installed!"
            exit 255
        fi
    fi
done

# Get and compile cURL, with custom CA bundle.
sudo mkdir -p $CURL_CA_DIR
if [ $? != 0 ]; then
    echo "\nCouldn't create the directory to hold the CURL CAs: ${CURL_CA_DIR}!"
    exit 254
fi

echo "\nDownloading curl certs and sources..."
wget --quiet $CURL_CA_BUNDLE -O curl_cacert.pem \
    && sudo $INSTALL_SCRIPT curl_cacert.pem $CURL_CA_FILE
wget --quiet $CURL_REMOTE_ARCHIVE \
    && echo "Extracting the curl sources, please wait..." \
    && gunzip -c $CURL_TAR_GZ | tar -xf - \
    && cd $CURL_DIR \
    && echo "Configuring and compiling curl...\n" \
    && ./configure --prefix="$INSTALL_DIR" --with-ca-bundle=${CURL_CA_FILE} \
    && gmake \
    && sudo make install \
    && cd "$START_FOLDER" \
    && rm -rf $CURL_DIR $CURL_TAR_GZ
if [ $? != 0 ]; then
    echo "\nCouldn't download and install cURL!"
    exit 253
fi

# Get and compile git.
export LDFLAGS
export CPPFLAGS
export PATH="${PATH}:${INSTALL_DIR}/bin"
echo "\nDownloading git sources using the newly compiled curl..."
curl --silent -O $GIT_REMOTE_ARCHIVE \
    && echo "Extracting git sources, please wait..." \
    && gunzip -c $GIT_TAR_GZ | tar -xf - \
    && cd $GIT_DIR \
    && echo "Configuring and compiling git with $INSTALL_DIR as CURLDIR...\n" \
    && CURLDIR="$INSTALL_DIR" ./configure --prefix=${INSTALL_DIR} --without-tcltk \
    && gmake \
    && sudo gmake install INSTALL=${INSTALL_SCRIPT} \
    && cd $START_FOLDER \
    && rm -rf $GIT_DIR $GIT_TAR_GZ
if [ $? != 0 ]; then
    echo "\nCouldn't download and install Git!"
    exit 252
fi

# Add some useful stuff to ~/.profile
echo "\nAdding git-related stuff to ~/.profile ..."
if [ -f ~/.profile ]; then
    echo 'alias git-init="git init --template='${INSTALL_DIR}'/share/git-core/templates"'\
        >> ~/.profile
    echo 'export GIT_EXEC_PATH='${INSTALL_DIR}'/libexec/git-core'\
        >> ~/.profile
    echo 'export PATH=$PATH:'${INSTALL_DIR}'/bin' >> ~/.profile
fi

echo "Done!\n"
