#!/usr/bin/env python3

import subprocess
import sys
import urllib.request
import json

zpool_status = subprocess.run(["zpool", "status"],
               capture_output=True,
               check=True,
               text=True,)

lines = zpool_status.stdout.splitlines()
data = { "state": None }
vdevs = { "vdevs": [] }
webhook_url = 'YOUR_WEBHOOK_URL_HERE'

def send_discord_alert(message):
    payload = {"content": message}
    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(
        webhook_url,
        data=data,
        headers={"Content-Type": "application/json",
                 "User-Agent": "zfs-healthcheck-script",
                },
        method="POST")
    urllib.request.urlopen(req)

for line in lines:
    stripped = line.strip()

    if stripped.startswith("state:"):
        data["state"] = stripped.split(":", 1)[1].strip()

    elif stripped.startswith("scsi"):
            cols = stripped.split()
            vdevs["vdevs"].append({
            "name": cols[0],
            "vdev_state": cols[1],
            "read": int(cols[2]),
            "write": int(cols[3]),
            "chksum": int(cols[4]),
            })


if data["state"] != 'ONLINE':
    discord_message = f" :warning: Issues have been detected with the pool, the current state is: {data["state"]}"
    send_discord_alert(discord_message)
elif data["state"] == 'ONLINE':
    send_discord_alert('ZFS Pool is overall healthy')

any_vdev_issue = False

for vdev in vdevs["vdevs"]:
    if vdev["vdev_state"] != 'ONLINE':
        vdev_down = f":warning: issues detected with the following drive(s) being down: {vdev}"
        send_discord_alert(vdev_down)
        any_vdev_issue = True
    elif vdev["read"] != 0 or vdev["write"] != 0 or vdev["chksum"] !=0:
        vdev_fault = f":warning: minor fault detected with the following drive(s), see error counts: {vdev}"
        send_discord_alert(vdev_fault)
        any_vdev_issue = True

if not any_vdev_issue:
        send_discord_alert('All drives are healthy')
