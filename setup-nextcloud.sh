#!/usr/bin/env bash

HSDIR_ROOT=/var/lib/tor

set -e

source utils.sh

sudo ./setup-nextcloud-with-permissions.sh

#Retrieve the Hidden Service address configured.
ONION_URL=$(sudo cat $HSDIR_ROOT/nextcloud/hostname)
HS_URL="http://${ONION_URL}:81"    
green_msg "\n\nCopy and paste the next address in your Tor browser:\n"
green_msg "$HS_URL\n\n"
echo ${HS_URL} | xclip -selection c
green_msg "The Onion Hidden Service address was copied to your clipboard.\n\n"

FF_EXIST=$(which firefox)
if [ x$FF_EXIST == "x" ]; then
    red_msg "\n\nFirefox is not installed.\n"
else        
    firefox http://127.0.0.1:81 &
fi