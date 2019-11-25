#!/usr/bin/env bash

test(){

    # sudo bash -c 'printf "deb https://deb.debian.org/debian buster-backports main contrib" > /etc/apt/sources.list.d/buster-backports.list'
    # #sudo printf "deb http://deb.debian.org/debian buster-backports main contrib" > /etc/apt/sources.list.d/buster-backports.list
    # sudo apt update

    apt --assume-yes install torbrowser-launcher -t buster-backports
    torbrowser-launcher
    
    EXISTS=$(which torbrowser-launcher)
    if [ $EXISTS == "" ]; then
        install tor browser launcher, run tor browser launcher
    fi


}

test