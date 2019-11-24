#!/usr/bin/env bash

test(){

    printf "deb http://deb.debian.org/debian buster-backports main contrib" > /etc/apt/sources.list.d/buster-backports.list
    apt update

    apt --assume-yes install torbrowser-launcher -t buster-backports
    

}

test