#!/usr/bin/env bash

HSDIR_ROOT=/var/lib/tor

sudo ./setup-nextcloud-with-permissions.sh
ONION_URL=$(sudo cat $HSDIR_ROOT/nextcloud/hostname)
#firefox http://127.0.0.1:81 &
TBB_EXIST=$(which tor-browser)
if [ x$TBB_EXIST == "x" ]; then
    torbrowser-launcher http://$ONION_URL:81 &
else    
    printf "\n\n=====================\n"
    printf "    http://$ONION_URL:81\n\n"
    printf "=====================\n\n"
    tor-browser http://$ONION_URL:81 &
    firefox http://127.0.0.1.81 &
fi