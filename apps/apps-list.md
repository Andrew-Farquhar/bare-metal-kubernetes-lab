## Apps deployed to the cluster

# Pi-Hole:
- Deployed using helm chart + custom values. Deployment was more involved, so a full write-up of the deployment is available here - ```apps/Pi-Hole/README.md```
- Provides DNS query filtering/blocking for ads and telemetry trackers and provides local DNS records & resolution.

# Mealie: 

- Deployed using manifest written manually following templates found online. Helm charts may be available, however, decided to spend the time manually writing the manifest for practice.
- Recipe tracking app

# Plex:
- Deployed using helm chart + custom values. Deployment was more involved so a full write-up of the deployment is available here - ```apps/plex/README.md```
- Provides media library playback and organisation. 

# Immich:
- Deployed using Helm with a CloudNativePG PostgreSQL database. Deployment was reasonable involved. Full write-up of deployment is available here - ```apps/Immich/README.md```
- Self-hosted photo and video management platform. Continually backs-up and hosts images taken on Mobile devices.
