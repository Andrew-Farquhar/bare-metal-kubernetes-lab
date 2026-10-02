#!/bin/bash

# set the current date for snapshot
current_date=$(date +%F)

# takes weekly snapshot
zfs snapshot mediapool/media@weekly-$current_date

# remove old weekly snapshot, keeping last 2 intact
zfs list -H -t snapshot -o name -s creation | grep '@weekly' | head -n -2 | xargs -r zfs destroy
