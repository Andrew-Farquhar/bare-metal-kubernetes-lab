# Kubernetes Homelab

A bare-metal kubernetes homelab built from Dell OptiPlex Micro systems focused on hands-on learning of Kubernetes, networking, storage and platform engineering.

# Project Goals

The aim of the project is to build and operate a small, production inspired Kubernetes environment from the ground up. 

The initial implementation will prioritise understanding the mechanics of the individual components rather than hiding complexity behind pre-built distributions or automation (although this may be implemented in later iterations of the project).

# Key areas of focus:

- Kubernetes cluster architecture and operations
- kubeadm cluster bootstrapping
- Container runtimes and nerdctl
- Kubernetes networking and CNI configuration
- Utilising a mix of persistent and network-attached storage
- Service discovery and application networking
- Monitoring and observability
- Failure recovery and cluster maintenance
- Documentation and version control 
- Automation (introduced once underlying systems are confidently administered and understood)

# Hardware

| Component | Specification |
|-----------|---------------|
| Nodes | 5 x Dell OptiPlex 9010 Micro (this may drop to 3 in later iterations) |
| CPU | Intel Core i5-4590T |
| Memory | 8GB DDR3L (per node) |
| Storage | 128 GB SATA SSD (per node) |
| Networking | Cat6 Ethernet to Gigabit unmanaged switch (with scope to move to managed switch) |

A sixth node is available and may eventually be used for networking (router/firewall).

# Planned Kubernetes Stack

The initial cluster will use:

- Debian 13
- Kubernetes
- kubeadm
-  containerd
- nerdctl
- A manually configured CNI
- NFS-backed persistent storage

The exact CNI and additional Kubernetes components will be documented as the implementation progresses.

# Planned Workloads

The cluster is intended to host a mixture of stateful and stateless self-hosted applications, including:

- pihole
- Immich
- Mealie
- Wanderer
- AdventureLog
- Smart Home Assistant
- Paperless-ngx
- Plex
- Tailscale
- Monitoring and supporting infrastructure

Some existing services will remain on the NAS where their storage, hardware or operational requirements make that the more appropriate architecture.

# Learning Approach

The cluster will initially be built and configured manually.

Automation will be introduced progressively once the underlying components are understood.

The project will document not only the final configuration, but also:

- Architectural decisions
- Problems encountered
- Troubleshooting and recovery
- Changes in design
- Lessons learned
- Operational testing

The intention is to treat the homelab as a practical platform engineering project rather than simply a collection of applications running on Kubernetes.

# Project Status

Phase 0 — Planning

- [x] Define project goals
- [x] Select hardware
- [x] Define initial service architecture
- [x] Select the node operating system
- [x] Prepare Git repository structure
- [ ] Install and configure first Kubernetes node
- [ ] Bootstrap Kubernetes control plane
- [ ] Configure CNI
- [ ] Join additional nodes
- [ ] Configure persistent storage
- [ ] Deploy first workload
- [ ] Implement monitoring
- [ ] Test node failure and workload recovery


This README will evolve alongside the project.
