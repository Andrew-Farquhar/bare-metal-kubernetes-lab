#!/bin/bash

target_ip=$(curl -s https://ipinfo.io/ip)
date=$(date)

if [ "$(docker ps -a -f name=vpn-client --format '{{.State}}')" != "exited" ]; then

    current_ip=$(docker exec vpn-client curl -s https://ipinfo.io/ip)

    if [ "$current_ip" = "$target_ip" ]; then
        docker stop service-a service-b service-c service-d vpn-client
        echo "containers stopped at $date. Container IP identified as $current_ip"
    else
        exit 1
    fi

else
    exit 1
fi
