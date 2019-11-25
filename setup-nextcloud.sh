#!/usr/bin/env bash

HSDIR_ROOT=/var/lib/tor

sudo ./setup-nextcloud-with-permissions.sh
ONION_URL=$(sudo cat $HSDIR_ROOT/nextcloud/hostname)
#firefox http://127.0.0.1:81 &
torbrowser-launcher http://$ONION_URL:81 &
