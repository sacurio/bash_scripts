#!/usr/bin/env bash

source utils.sh

#Interrupt the script execution on first error
set -e

#Setup variables (change values if you need)
TORRC_ROOT=/etc/tor
HSDIR_ROOT=/var/lib/tor
NEXTCLOUD_PORT=81
SEARCH_TEXT="NextCloud hidden service configuration"

USER="debian-tor"
GROUP="debian-tor"

TOR_STATUS=-1

ONION_URL='-'

#Code block for Hidden Services stuffs.

# If Tor is active, will try to add a configuration
# for the NextCloud hidden service, if it hasn't 
# already been added. Creates a backup copy of the original
# torrc during operation.
configure_hidden_service() {

    printf "Configuring hidden service...\n"
    
    if [ "$TOR_STATUS" != "inactive" ]; then
        echo "Backing up original torrc configuration..."

        LINES_FOUND=$(grep "$SEARCH_TEXT" $TORRC_ROOT/torrc | wc -l)

        if [ $LINES_FOUND == "0" ]; then
            cp -pv $TORRC_ROOT/torrc $TORRC_ROOT/torrc.orig
            # Inserts new HiddenService declarations around line 78
            # This is sensitive to the original layout of torrc
            # Ideally, a different way of locating the right point
            # of insertion would be used.
            sed -e "78 a # NextCloud hidden service configuration." \
                -e "78 a HiddenServiceDir $HSDIR_ROOT/nextcloud/" \
                -e "78 a HiddenServicePort $NEXTCLOUD_PORT 127.0.0.1:$NEXTCLOUD_PORT\n" \
                <$TORRC_ROOT/torrc.orig \
                >$TORRC_ROOT/torrc
        fi        
        
        printf "Restarting Tor service... \n"
        systemctl restart tor
        wait_tor_service_active
        ONION_URL=$(cat $HSDIR_ROOT/nextcloud/hostname)
        green_msg "\n\nOnion HiddenService:  $ONION_URL \n\n"
    fi

}

#Wait for the Tor service status to be active. It tries 20 attempts before failing.
wait_tor_service_active() {

    max_attempts=20
    current_attempt=1

    TOR_STATUS=$(systemctl is-active tor)
    while [ "$TOR_STATUS" != "active" ]; do
        ((current_attempt++))
        if [ $current_attempt -ge $max_attempts ]; then
            printf "Tor Service took too long to become active - check any possible error messages"
            exit 1
        else
            sleep 1
            TOR_STATUS=$(systemctl is-active tor)
        fi
    done

}

#================HIDDEN SERVICES================

#================PACKAGES================

# Usage: ensure_package <PKG> <APT_UPDATE>
# Takes the name of a package to install if not already installed,
# and optionally a 1 if apt update should be run after installation
# has finished.
ensure_package() {
    local program
    local execute_apt_update
    program="${1}"
    execute_apt_update="${2}"
    
    printf "\\n\\n Checking ${program} in the system...\\n\\n\\n"
    dpkg-query -W --showformat='${status}\n' ${program} >/dev/null 2>&1 
    PKG_EXISTS=$?

    if [ "x$PKG_EXISTS" == "x1" ]; then
        printf "==========================\\n"
        red_msg " ${program} is not installed\\n"
        printf "==========================\\n\\n"
        apt --assume-yes install ${program}

        if [ "x$execute_apt_update" == "x1" ]; then
            apt update
            date
        fi
        
    else
        printf "======================\\n"
        green_msg " ${program} is installed\\n"
        printf "======================\\n"
    fi  
}

# Usage: install_pkg <PKG>
# Takes the name of the package and install it.
install_pkg() {
    program=$1
    yellow_msg "Installing ${program}...\\n"
    apt --assume-yes install ${program}
}

# Usage: install_pkg <PKG>
# Takes the name of the package and uninstall it.
purge_pkg() {
    program=$1
    yellow_msg "Uninstalling ${program}...\\n"
    apt-get --assume-yes --purge remove ${program}
}

#Uninstall a group of packages.
purge_packages() {
    purge_pkg "tor"
    purge_pkg "net-tools"
    purge_snap_pkg "nextcloud"
    purge_pkg "snapd"
}

#Install a group of packages.
ensure_packages() {
    ensure_package "ntp" 1
    ensure_package "tor"
    ensure_package "net-tools"    
    ensure_package "xclip"
    ensure_package "snapd"
}

#================PACKAGES================

#================SNAP PACKAGES================

# Usage: ensure_snap_pkg <PKG>
# Takes the name of a snap package to install if not already installed.
ensure_snap_pkg() {
    local program
    program="${1}"

    printf "\\n\\n Checking ${program} in the system...\\n\\n\\n"

    PKG_OK=$(snap list | grep ${program})

    if [ "x$PKG_OK" == "x" ]; then
        printf "=============================\\n"
        red_msg " ${program} is not installed\\n"
        printf "==============================\\n\\n"
        install_pkg ${program}
    else
        printf "=========================\\n"
        yellow_msg " ${program} is installed\\n"
        printf "=========================\\n"
    fi
}

# Usage: install_snap_pkg <PKG>
# Takes the name of the snap package and install it.
install_snap_pkg() {
    program=$1
    yellow_msg "Installing snap package ${program}...\\n"
    snap install ${program}
}

# Usage: purge_snap_pkg <PKG>
# Takes the name of the snap package and uninstall it.
purge_snap_pkg() {
    program=$1
    yellow_msg "Uninstalling snap package ${program}...\\n"
    snap remove ${program}
}

#Install NextCloud snap package.
check_nextcloud_snap_packages() {
    install_snap_pkg "nextcloud"
}

#================SNAP PACKAGES================

#================NEXTCLOUD================

#Configure the NextCloud port to be used.
configure_nextcloud() {
    yellow_msg "Configuring NextCloud...\\n"
    snap set nextcloud ports.http=${NEXTCLOUD_PORT}
}

#================NEXTCLOUD================

# Run the main functionality.
# Requires sudo in order to run correctly.
main() {

    ensure_packages
    check_nextcloud_snap_packages
    configure_nextcloud
    configure_hidden_service
    # purge_packages
        
}

main