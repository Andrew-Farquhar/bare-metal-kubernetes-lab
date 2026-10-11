# MetalLB

## Overview

MetalLB was implemented for this bare-metal Kubernetes cluster to provide a method for advertising external IP addresses on the physical LAN. This allows applications to be accessed through a consistent IP address, without needing to access individual node IPs or specify NodePorts.

MetalLB was installed in native mode using Layer 2 configuration. In this mode one node advertises each assigned IP address on the LAN while Kubernetes handles forwarding traffic to the appropriate Service and it's pods. If the node advertising an IP becomes unavailable another eligible node can take over the advertisement.

## Configuration

### Installation

* MetalLB version: v0.16.1
* Installation method: Native manifest

MetalLB was installed using the native manifest provided by the official documentation:

```bash
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.16.1/config/manifests/metallb-native.yaml
```

### IP Address Pool

The `IPAddressPool` resource defines the external IP addresses available for allocation to Kubernetes Services.

The configured address pool contains:

* `192.168.1.241/32` — application traffic, currently assigned to Traefik.
* `192.168.1.243/32` — DNS traffic, currently assigned to Pi-hole.

These addresses were selected because they sit outside the router's DHCP address pool thus avoiding conflicts with dynamically assigned client addresses.

The Kubernetes API VIP (`192.168.1.240`) is excluded because it is managed separately using Keepalived and HAProxy outwith Kubernetes.


### Service Integration

MetalLB integrates with Kubernetes Services of type `LoadBalancer`. When a Service requests an external IP address from the configured pool, MetalLB allocates an available address and advertises it on the LAN.

Traefik is configured as a `LoadBalancer` Service with the address `192.168.1.241`. It's Service exposes HTTP on port 80 and HTTPS on port 443 allowing applications to be accessed through their configured hostnames without specifying NodePorts.

Pi-hole uses a separate LoadBalancer Service with the address `192.168.1.243`, exposing DNS over both TCP and UDP on port 53.

MetalLB provides the external IP advertisement; Kubernetes handles forwarding traffic to the appropriate Service endpoints.

## Validation

MetalLB was validated by checking that its components were running, confirming the IP address pool and Layer 2 advertisement resources existed, and verifying that Traefik received its expected external IP address.

Application connectivity was then tested through the assigned IP address using the configured hostnames.

### Files

| File                           | Purpose                                                     |
| ------------------------------ | ----------------------------------------------------------- |
| `metallb-pool.yaml`            | Defines the external IP addresses available for allocation. |
| `metallb-l2advertisement.yaml` | Configures Layer 2 advertisement for the address pool.      |

## References

* https://metallb.io/installation/
* https://metallb.io/configuration/
