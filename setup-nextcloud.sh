#!/bin/bash

TORRC_ROOT=/etc/tor
ETC_TOR=/etc
HSDIR_ROOT=/var/lib/tor
HOSTNAME=$(uname -n)

USER="debian-tor"
GROUP="debian-tor"

HS_PORT=64738

TOR_STATUS=-1

ONION_URL='-'

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
        change_color 2
        printf "\nTor service status ${TOR_STATUS}\\n"
        change_color -1
    fi
}

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

change_color() {
    color=$1
    if [ "${color}" == "-1" ]; then
        tput sgr0
    else
        tput setaf "${color}"
    fi
}

purge_packages() {
    purge_pkg "tor"
    purge_pkg "net-tools"
    purge_pkg "snapd"
    purge_snap_pkg "nextcloud"
}

install_tor_browser(){
    printf "deb http://deb.debian.org/debian buster-backports main contrib" > /etc/apt/sources.list.d/buster-backports.list
    apt update
    sleep 5
    apt --assume-yes install torbrowser-launcher -t buster-backports
}

main() {

    check_for_package "tor"
    check_for_package "net-tools"
    check_for_package "snapd"
    install_snap_pkg "nextcloud"
    #install_tor_browser    

    # purge_packages

    check_tor_service_status

    change_color 4
    printf "\\nExiting...\\n\\n"
    change_color -1
}
#example nop
main
