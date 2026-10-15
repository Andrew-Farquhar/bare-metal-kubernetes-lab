## Apps deployed to the cluster

# Pi-Hole:
- Deployed using helm chart + custom values. Deployment was more involved, so a full write-up of the deployment is available here - ```apps/Pi-Hole/README.md```
- Provides DNS query filtering/blocking for ads and telemetry trackers and provides local DNS records & resolution.

# Mealie: 

- Deployed using manifest written manually following templates found online. Helm charts may be available, however, decided to spend the time manually writing the manifest for practice.
- Recipe tracking app
