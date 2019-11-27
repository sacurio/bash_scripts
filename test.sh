#!/usr/bin/env bash

source utils.sh

function test {
    
    yellow_msg "Please input the next values in order to configure the NextCloud admin account:\n"
    read -p "Username: " admin_user
    while true; do
        read -s -p "Password: " admin_password
        echo
        read -s -p "Password (again): " admin_password2
        echo
        [ "$admin_password" = "$admin_password2" ] && break
        echo "Please try again"
    done
    
    green_msg "\n======================================================\n"
    green_msg "Username:${admin_user}     Password:${admin_password}   "
    green_msg "\n======================================================\n"

    printf "Aplying credentials values to NextCloud admin account...\n"

}

test