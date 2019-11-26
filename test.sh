#!/usr/bin/env bash

source utils.sh

function test {
    
    url="domain.your.ec"

    sleep 10
    /snap/bin/nextcloud.occ config:system:set trusted_domains 2 --value=${url}
    # sudo -i nextcloud.occ config:system:get trusted_domains
    green_msg "Trusted domain added to NextCloud instance succesfully.\n"
}

test