#!/usr/bin/env bash

#set -xe

TORRC_ROOT=/etc/tor
ETC_TOR=/etc
HSDIR_ROOT=/var/lib/tor
HOSTNAME=$(uname -n)
TOR_SERVICE_CHECKER=1
TOR_SERVICE_CHECKER_MAX=5
NEXTCLOUD_PORT=81
SEARCH_TEXT="NextCloud hidden service configuration"

# USER="debian-tor"
# GROUP="debian-tor"

USER="debian-tor"
GROUP="debian-tor"

TOR_STATUS=-1

ONION_URL='-'

#================TOR================


install_tor_browser_launcher() {
    printf "deb http://deb.debian.org/debian buster-backports main contrib" >/etc/apt/sources.list.d/buster-backports.list
    apt update
    apt --assume-yes install torbrowser-launcher -t buster-backports
}

ensure_tor_browser(){
    EXISTS=$(which tor-browser)
    if [ x$EXISTS == "x" ]; then
        INSTALLER_EXISTS=$(which torbrowser-launcher)
        if [ x$INSTALLER_EXISTS == "x" ]; then
            echo "Installing tor browser installer, since it didn't exist"
            install_tor_browser_launcher
        fi
    fi
}

#================TOR================

#================HIDDEN SERVICES================

configure_hidden_service() {

    printf "Configuring hidden service...\n"
    # printf "${TOR_STATUS} \n"

    if [ "$TOR_STATUS" != "inactive" ]; then
        echo "Backing up original torrc configuration..."

        LINES_FOUND=$(grep "$SEARCH_TEXT" $TORRC_ROOT/torrc | wc -l)

        if [ $LINES_FOUND == "0" ]; then
            cp -pv $TORRC_ROOT/torrc $TORRC_ROOT/torrc.orig
            sed -e "78 a # NextCloud hidden service configuration." \
                -e "78 a HiddenServiceDir $HSDIR_ROOT/nextcloud/" \
                -e "78 a HiddenServicePort $NEXTCLOUD_PORT 127.0.0.1:$NEXTCLOUD_PORT\n" \
                <$TORRC_ROOT/torrc.orig \
                >$TORRC_ROOT/torrc
        fi        
        
        sleep 2
        printf "Restarting Tor service... \n"
        systemctl restart tor
        wait_tor_service_active
        sleep 10
        ONION_URL=$(cat $HSDIR_ROOT/nextcloud/hostname)
        change_color 2
        printf "\n\nOnion HiddenService url:  $ONION_URL \n\n"
        change_color -1

    fi

}

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

check_packages() {
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

check_snap_packages() {
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

#================NEXTCLOUD================

main() {

    apt-get update
    check_packages
    check_snap_packages
    sleep 2
    configure_nextcloud
    sleep 2
    configure_hidden_service
    ensure_tor_browser
    # purge_packages
    
    change_color 4
    printf "\\nExiting...\\n\\n"
    change_color -1
}

main