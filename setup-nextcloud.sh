#!/bin/bash

TORRC_ROOT=/etc/tor
ETC_TOR=/etc
HSDIR_ROOT=/var/lib/tor
HOSTNAME=$(uname -n)
TOR_SERVICE_CHECKER=1
TOR_SERVICE_CHECKER_MAX=5
NEXTCLOUD_PORT=81

# USER="debian-tor"
# GROUP="debian-tor"

USER="debian-tor"
GROUP="debian-tor"

TOR_STATUS=-1

ONION_URL='-'

#================TOR================

check_tor_service_status() {
    ## Validating services status
    TOR_STATUS=$(systemctl is-active tor)

    printf "\nChecking Tor service status...\n"

    if [ "$TOR_STATUS" == "inactive" ]; then
        change_color 1
        printf "\nTor service status ${TOR_STATUS}\\n"
        change_color -1

        change_color 4
        echo "Starting tor service..."
        change_color -1
        systemctl start tor
        sleep 5
        check_tor_service_status
    else        
        if [ ${TOR_SERVICE_CHECKER} -lt ${TOR_SERVICE_CHECKER_MAX} ] ; then
            printf "\nChecking ${TOR_SERVICE_CHECKER} / ${TOR_SERVICE_CHECKER_MAX}\\n"
            change_color 2
            printf "\nTor service status ${TOR_STATUS}\\n"
            change_color -1
            $TOR_SERVICE_CHECKER += 1
        fi
    fi
}

install_tor_browser() {
    printf "deb http://deb.debian.org/debian buster-backports main contrib" >/etc/apt/sources.list.d/buster-backports.list
    apt update
    sleep 5
    apt --assume-yes install torbrowser-launcher -t buster-backports
}

#================TOR================

#================HIDDEN SERVICES================

configure_hidden_service(){
    
    printf "Configuring hidden service...\n"
    # printf "${TOR_STATUS} \n"

    if [ "$TOR_STATUS" != "inactive" ]; then
        printf "Backing up original torrc configuration"
        cp -pv $TORRC_ROOT/torrc $TORRC_ROOT/torrc.orig

        sed -e "78 a # NextCloud hidden service configuration." \
            -e "78 a HiddenServiceDir $HSDIR_ROOT/nextcloud/" \
            -e "78 a HiddenServicePort $NEXTCLOUD_PORT 127.0.0.1:$NEXTCLOUD_PORT\n" \
            < $TORRC_ROOT/torrc.orig \
            > $TORRC_ROOT/torrc
        sleep 2
        printf "Restarting Tor service... \n"
        systemctl restart tor
        ONION_URL=$(cat /var/lib/tor/nextcloud/hostname)
        change_color 2
        printf "\n\nOnion HiddenService url:  $ONION_URL \n\n"
        change_color -1

    fi
    
}

#================HIDDEN SERVICES================

#================PACKAGES================

check_for_package() {
    local program
    program="${1}"
    successfully_message="install ok installed"

    printf "\\n\\n Checking ${program} in the system...\\n\\n\\n"

    command -v "${program}"

    PKG_OK=$(dpkg-query -W --showformat='${status}\n' ${program} | grep "${successfully_message}")

    if [ "${successfully_message}" != "$PKG_OK" ]; then
        printf "=============================\\n"
        change_color 1
        printf " ${program} is not installed\\n"
        change_color -1
        printf "==============================\\n\\n"
        install_pkg ${program}
    else
        printf "=========================\\n"
        change_color 2
        printf " ${program} is installed\\n"
        change_color -1
        printf "=========================\\n"
        #purge_pkg ${program}
    fi
}

install_pkg() {
    program=$1
    change_color 3
    printf "Installing ${program}...\\n"
    change_color -1
    apt --assume-yes install ${program}
}

purge_pkg() {
    program=$1
    change_color 3
    printf "Uninstalling ${program}...\\n"
    change_color -1
    apt-get --assume-yes --purge remove ${program}
}

purge_packages() {
    purge_pkg "tor"
    purge_pkg "net-tools"
    purge_pkg "snapd"
    purge_snap_pkg "nextcloud"
}

check_packages(){
    check_for_package "tor"
    check_for_package "net-tools"
    check_for_package "snapd"    
}

#================PACKAGES================

#================SNAP PACKAGES================

check_snap_pkg() {
    local program
    program="${1}"

    printf "\\n\\n Checking ${program} in the system...\\n\\n\\n"

    command -v "${program}"

    PKG_OK=$(snap list | grep ${program})

    if [ "" == "$PKG_OK" ]; then
        printf "=============================\\n"
        change_color 1
        printf " ${program} is not installed\\n"
        change_color -1
        printf "==============================\\n\\n"
        install_pkg ${program}
    else
        printf "=========================\\n"
        change_color 2
        printf " ${program} is installed\\n"
        change_color -1
        printf "=========================\\n"
    fi
}

install_snap_pkg() {
    program=$1
    change_color 3
    printf "Installing snap package ${program}...\\n"
    change_color -1
    snap install ${program}
}

purge_snap_pkg() {
    program=$1
    change_color 3
    printf "Uninstalling snap package ${program}...\\n"
    change_color -1
    snap remove ${program}
}

check_snap_packages(){
    install_snap_pkg "nextcloud"
}

#================SNAP PACKAGES================

#================UTIL================

change_color() {
    color=$1
    if [ "${color}" == "-1" ]; then
        tput sgr0
    else
        tput setaf "${color}"
    fi
}

#================UTIL================

#================NEXTCLOUD================

configure_nextcloud() {
    change_color 3
    printf "Configuring NextCloud...\\n"
    change_color -1
    sudo snap set nextcloud ports.http=${NEXTCLOUD_PORT}
}

launch_nextcloud(){
    change_color 3
    printf "Launching NextCloud...\\n"
    change_color -1
    . firefox http://127.0.0.1:${NEXTCLOUD_PORT}
}

#================NEXTCLOUD================

main() {

    apt-get update
    check_packages
    check_snap_packages    
    sleep 5
    configure_nextcloud
    sleep 10
    #launch_nextcloud
    configure_hidden_service

    #install_tor_browser

    # purge_packages

    check_tor_service_status

    change_color 4
    printf "\\nExiting...\\n\\n"
    change_color -1
}

main
