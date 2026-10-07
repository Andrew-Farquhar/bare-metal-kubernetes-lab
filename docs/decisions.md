# Why Debian 13?

Debian 13 was installed as the base OS for the Kubernetes nodes to provide a minimal but stable Linux environment while allowing the cluster components to be configured manually for learning purposes. Purpose built 'Kubernetes' Linux distributions were considered, however, these typically include out of the box configurations that would have hindered learning. 
Given Debian's reputation for reliability, this distribution also provides some assurance that the OS is less likely to be the root cause of faults. 

# Why one filesystem? 

The nodes are configured to use one filesystem as opposed to separate partitions for /var and /srv. This decision may be reversed in future iterations but for the moment this configuration provides a Linux environment that is familiar, allowing for deeper focus on Kubernetes.

# Why 3 control planes?

The aim of using three nodes as control planes is to explore the concepts and realities of creating Highly Available infrastructure. This also introduces the added bonus of resiliency for applications and workloads that are used consistently.

# Why have the 3 control planes configured as workers also?

This is purely to facilitate exploring how much load can be applied to the system. The underlying hardware is somewhat limited but from a personal point of view, the cost involved is driving the decision to yield as much compute as possible.

# Why HAProxy and KeepAlived?

 Using these services in tandem provided a simple but effective HA network and facilitates using three control-planes. With both services monitoring the state of the node and the opposing service (Keepalived -> HAproxy & HAProxy -> node's api-server), it ensures that only a healthy node can own the Virtual IP address and that it's kube-api-server can receive traffic.

# Why a bare-metal install of HAProxy and KeepAlived?

Containerization of these services was considered but eventually abandoned for the initial phases of the project. Given that the main objective of the project is to learn Kubernetes, introducing additional layers on top of new tools may add an additional level of complexity when troubleshooting. Bare-Metal installs simplify this.

# Longhorn for persistent storage

- Implemented Longhorn for persistent storage to allow for stateful pods to be able to move between nodes without losing data and thus keeping in line with the HA approach to the cluster by avoiding tying application storage to any individual node. Longhorn also provides replicated block storage within the cluster and allows for backups to be create which can be stored on the NAS. 

- Restricted Longhorn to 2 replicas and set configuration to only create default storage disks on labelled nodes (worker nodes in this case). Avoids resource contention on control-plane nodes with etcd.

- Node01 holds longhorn management processes & pods also. Initially implemented until resource utilisation of these can be confirmed before deploying onto remaining control-plane nodes. If low can be replicated across other control-plane nodes again keeping HA approach.

- Longhorn uses node-local disks as storage, including existing filesystem rather than separate partition.




