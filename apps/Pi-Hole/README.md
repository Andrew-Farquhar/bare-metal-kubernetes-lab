# Pi-hole Deployment

## Overview

Pi-Hole has been deployed into the cluster to provide ad-blocking and increased privacy by handling DNS query filtering and blocking DNS queries that would normally allow for connections to advertisements and telemetry endpoints. Pi-Hole is also responsible for maintaining local DNS Records, allowing for connectivity to apps in cluster from any device on the network using a custom URL as opposed to attempting to connect over an IP address.

## Deployment

- **Namespace:** ```apps```
- **Helm chart:** ```mojo2600/pihole```
- **Chart version:** ```2.38.0```
- **Application version:** ```2026.07.2```
- **Configuration location:** ```~/helm/pihole/values.yaml```

To install and configure Pi-Hole using a helm chart, the helm chart was added to the Helm Repo and it's default values copied into a yaml file. From there objects such as DNS service, Loadbalancing, web-interface configurations were reviewed to get an idea of how the helm chart expected these configs to be defined. Once this was clear, a ```values.yaml``` file was created with the configurations that needed to be specified for this particular cluster. This was then deployed using the helm command, passing our values file in as an argument.

## Networking

Describe how DNS traffic reaches Pi-hole and how the web interface is accessed.

- **DNS Service:** ```LoadBalancer```
- **DNS LoadBalancer IP:** ```192.168.1.243```
- **Web interface hostname:** ```pihole.home```
- **Ingress / routing:** ```HTTPRoute via Traefik```

DNS and Web-UI traffic were separated using Traefik and MetalLB. Having MetalLB provide a separate IP to be advertised specifically for DNS traffic lets Pi-Hole have access to the IP's port 53 for UDP and TCP traffic to be queried directly by devices on the Network. Also allows for DNS to be indepently available of the WebUI.

The WebUI's traffic can be routed through Traefik, keeping it consistent with other applications in the apps namespace and allowing for a local DNS record to be created. 

## Storage

- **StorageClass:** ```Longhorn```
- **Persistent volume size:** ```1Gi```

Persistent storage applied to host Pi-Hole's gravity database and generally allow for application data to survive pod recreation/movement. 

## Configuration

Document the important configuration decisions, including:

- DHCP remains managed by the router. This allows static DHCP leases to remain managed by the router and devices to renew their leases even if Pi-hole is unavailable.
- DNS is provided by Pi-hole.
- DNS listening mode was set to all, allowing DNS requests from the LAN network.
- Blocklists and local DNS records were added once the WebUI became available.
- WebUI password configured using Kubernetes secret to avoid hardcoding value in values.yaml

## Validation

Describe the tests performed to confirm the deployment was working.

- DNS resolution test: From another LAN device, ran ```dig@192.168.1.243 google.com``` to directly query the new Pi-Hole instance. Returned successfully.

- Web interface access:  The web interface was accessible through pihole.home 

- Client migration: The Pi-Hole Query Log showed DNS queries arriving immediately, however, a previous instance of Pi-Hole running in docker on a NAS was left up for 48 hours to allow for clients to migrate to the new service following DHCP lease renewals.

## Outcome

A working instance of Pi-Hole providing DNS query filtering and local DNS resolution from the Kubernetes cluster.
