#!/usr/bin/env bash

source utils.sh

function test {
    red_msg "Please entry the name of the admin user for NextCloud:\n"
    read admin_user
    red_msg "Please entry the password of the admin user for NextCloud:\n"
    read admin_password

    url="domain.your.ec"

    green_msg "\n======================================================\n"
    green_msg "     Username:${admin_user}     Password:${admin_password}   \n"
    green_msg "======================================================\n"

    red_msg "${url}\n"

    /snap/bin/nextcloud.manual-install ${admin_user} ${admin_password}
    /snap/bin/nextcloud.occ config:system:set trusted_domains 2 --value=${url}
    # sudo -i nextcloud.occ config:system:get trusted_domains
    green_msg "Trusted domain added to NextCloud instance succesfully.\n"
}

test