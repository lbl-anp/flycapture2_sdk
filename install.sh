#!/bin/bash

# Strict env settings
# http://tldp.org/LDP/abs/html/options.html
# Abort script at first error, when a command exits with non-zero status (except in until or while loops, if-tests, list constructs)
set -e
# Attempt to use undefined variable outputs error message, and forces an exit
set -u
# Causes a pipeline to return the exit status of the last command in the pipe that returned a non-zero return value.
set -o pipefail

mydir="$(dirname "$(realpath -s $0)")"
arch="$(dpkg --print-architecture)"  #amd64, etc
ubuntu_release="$(lsb_release -cs)"  # bionic, etc
version="2.13.3.31"
user=$(whoami)
grpname="flirimaging"

launch_help () {
    # Launch help and exit
    echo "Spinnaker SDK installer"
    echo ""
    echo "Arguments:"
    echo ""
    echo "-h --help Show this text."
    echo "-v --version (${version} or other version in this repo)"
    echo "-u --user User to add to ${grpname} group (defaults to \$whoami)"
    echo ""
}

echo "Reading cmd line args:"
for arg_raw in "$@"; do
    echo "    ${arg_raw}"
    arg_key="${arg_raw%%=*}"
    arg_val="${arg_raw#*=}"
    case $arg_raw in
        -h|--help)
            launch_help
            exit 0
            ;;
        -v=?*|--version=?*)
            version="${arg_val}"
            ;;
        -u=?*|--user=?*)
            user="${arg_val}"
            ;;
        # All other style args cause an error
        *)
            echo "Unknown cmd line arg: ${arg_raw}"
            exit 1
            ;;
    esac
    shift
done

workdir="${mydir}/${version}/${ubuntu_release}/${arch}"

if [[ ! -d "$workdir" ]]; then
    echo "Cannot find version/platform/arch: ${workdir}"
    exit 1
fi

# sudo wrapper to handle root and non-root install with sudo
_sudo () {
    if [[ $EUID -ne 0 ]]; then
        sudo $@
    else
        $@
    fi
}

echo "Installing deps..."
sudo apt-get install -y \
    libraw1394-11 \
    libgtkmm-2.4-dev \
    libglademm-2.4-dev \
    libgtkglextmm-x11-1.2-dev \
    libusb-1.0-0

# Go to SDK
cd $workdir

# Taken from install_spinnaker.sh
echo "Installing flycapture2 packages..."
sudo dpkg -i libflycapture-2*
sudo dpkg -i libflycapturegui-2*
sudo dpkg -i libflycapturevideo-2*
sudo dpkg -i libflycapture-c-2*
sudo dpkg -i libflycapturegui-c-2*
sudo dpkg -i libflycapturevideo-c-2*
sudo dpkg -i libmultisync-2*
sudo dpkg -i libmultisync-c-2*
sudo dpkg -i flycap-2*
sudo dpkg -i flycapture-doc-2*
sudo dpkg -i updatorgui*

# Taken from configure_spinnaker.sh
echo "Adding user ${user} to group ${grpname}."
sudo groupadd -f $grpname
sudo usermod -a -G $grpname $user
echo "UDEV rules must be installed separately ..."

# Done!
echo "Flycapture2SDK installation complete. A reboot may be required on some systems for changes to take effect"
