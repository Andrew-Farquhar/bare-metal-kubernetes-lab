#!/bin/bash

heartbeat_file="/home/andrewnas/scripts/container-health/heartbeat.state"
current_hour=$(date +%H)
today=$(date +%Y-%m-%d)
webhook_url="YOUR_WEBHOOK_URL_HERE"
state_file="/home/andrewnas/scripts/container-health/containers.state"
down_containers=()

send_discord() {
    local message="$1"
    curl -s -H "Content-Type: application/json" -d "{\"content\": \"${message}\"}" "$webhook_url" > /dev/null
}

while read -r container state; do
    if [[ "$state" != "running" ]]; then
        down_containers+=("$container")
    fi
done < <(docker ps -a --format '{{.Names}} {{.State}}') 

for container in "${down_containers[@]}"; do 
    if ! grep -qx "$container" "$state_file"; then
       echo "$container" >> "$state_file"
       send_discord "Container down: $container"
    fi
done

if [[ ${#down_containers[@]} -eq 0 ]]; then
    last_sent=""
    if [[ -f "$heartbeat_file" ]]; then
        last_sent=$(cat "$heartbeat_file")
    fi
    if [[ "$today" != "$last_sent" && "$current_hour" == "18" ]]; then
        send_discord "All Containers are healthy"
        echo "$today" > "$heartbeat_file"
    fi
fi

while read -r container state; do
    if [[ "$state" == "running" ]] && grep -qx "$container" "$state_file"; then
        sed -i "/^${container}$/d" "$state_file"
    fi
done < <(docker ps -a --format '{{.Names}} {{.State}}') 
