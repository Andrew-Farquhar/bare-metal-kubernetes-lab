# NAS Scripts

Small Bash and Python utilities used to automate maintenance and monitoring of the NAS.

The scripts are intentionally lightweight and generally rely on existing system utilities rather than introducing additional monitoring infrastructure.

## Scripts

### ZFS Snapshots

Automates ZFS snapshot creation and rotation.

* **Weekly snapshots** — retained for short-term recovery.
* **Monthly snapshots** — retained for longer-term recovery.
* Handles snapshot rotation so old snapshots are removed automatically.

### VPN Container Check

Checks that the expected network path is active before allowing dependent containers to continue operating.

The script compares the host's public IP with the public IP observed from the protected container network. If the expected VPN connection is not detected, the dependent containers are stopped.

### ZFS Health Check

Python script that checks the current state of the ZFS pool and its individual vdevs.

It monitors:

* Overall pool state.
* Individual drive state.
* Read errors.
* Write errors.
* Checksum errors.

Issues are reported through a Discord webhook.

### Container Health Check

Bash script that monitors Docker containers and reports containers that are no longer running.

It maintains a small state file so that persistent failures do not generate repeated alerts, while a daily heartbeat confirms that all containers are healthy when no issues are detected.

Recovered containers are removed from the failure state automatically.

## Configuration

Scripts containing notification functionality use a Discord webhook.

Webhook URLs and other environment-specific values should be configured locally and **must not be committed to the repository**.

The repository versions use placeholders where required.
