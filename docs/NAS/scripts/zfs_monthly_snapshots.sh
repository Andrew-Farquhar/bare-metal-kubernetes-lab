#!/bin/bash

# set the current date for snapshot
current_date=$(date +%F)

# takes monthly snapshot
zfs snapshot mediapool/media@monthly-$current_date

# Removes previous month's snapshot 
zfs list -H -t snapshot -o name -s creation | grep '@monthly' | head -n -1 | xargs -r zfs destroy 
