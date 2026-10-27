# Why Debian 13?

Debian 13 was installed as the base OS for the Kubernetes nodes to provide a minimal but stable Linux environment while allowing the cluster components to be configured manually for learning purposes. Purpose built 'Kubernetes' Linux distributions were considered, however, these typically include out of the box configurations that would have hindered learning. 
Given Debian's reputation for reliability, this distribution also provides some assurance that the OS is less likely to be the root cause of faults. 

# Why one filesystem? 

The nodes are configured to use one filesystem as opposed to separate partitions for /var and /srv. This decision may be reversed in future iterations but for the moment this configuration provides a Linux environment that is familiar, allowing for deeper focus on Kubernetes.

# Why 3 control planes?

The aim of using three nodes as control planes is to explore the concepts and realities of creating Highly Available infrastructure. This also introduces the added bonus of resiliency for applications and workloads that are used consistently.

# Why DHCP reservations instead of static IPs?

Node addresses are set as DHCP reservations on the router, not as static addresses configured in Debian. Reservations are simple to set up, and I preferred managing addressing in one place at the top of the network rather than on each node. The API VIP (192.168.1.240) and the MetalLB addresses sit outside the router’s DHCP pool so they can’t collide with leases.

The trade-off is that the cluster now depends on the router holding those reservations. Node IPs are hardcoded in the kubeadm join configs and the cluster’s certificates and etcd membership are tied to them, so a lost or changed reservation would break a node. If the router is ever replaced (for example by OPNsense), the reservations need recreating before the nodes come back up.

# Why have the 3 control planes configured as workers also?

This is purely to facilitate exploring how much load can be applied to the system. The underlying hardware is somewhat limited but from a personal point of view, the cost involved is driving the decision to yield as much compute as possible.

# Why HAProxy and KeepAlived?

 Using these services in tandem provided a simple but effective HA network and facilitates using three control-planes. With both services monitoring the state of the node and the opposing service (Keepalived -> HAproxy & HAProxy -> node's api-server), it ensures that only a healthy node can own the Virtual IP address and that it's kube-api-server can receive traffic.

# Why a bare-metal install of HAProxy and KeepAlived?

Containerization of these services was considered but eventually abandoned for the initial phases of the project. Given that the main objective of the project is to learn Kubernetes, introducing additional layers on top of new tools may add an additional level of complexity when troubleshooting. Bare-Metal installs simplify this.

# Why Flannel?

Flannel was the first CNI I came across and I went with it without comparing alternatives. It provides the pod network (10.244.0.0/16) and has worked as expected so far. The trade-off is that Flannel doesn’t enforce NetworkPolicy, so pods can currently talk to each other freely. If network policies become a requirement this is the component that would need replacing (Calico or Cilium).

# Why MetalLB?

MetalLB was recommended to me by a knowledgeable friend. Reading the installation guide the native Layer 2 mode was what settled it: a speaker pod runs on each node and one node is elected to advertise each assigned IP on the physical LAN, which was exactly what I needed. It’s also lightweight which was worth considering on a cluster with 8GB nodes. The trade-off with L2 mode is that all traffic for a given IP arrives at one node and is forwarded from there so it provides failover rather than load balancing across nodes.

# Why Gateway API?

Gateway API was chosen over Traefik-specific tooling so that application routing is defined using Kubernetes-standard resources such as Gateway and HTTPRoute. This also came as a recommendation from a knowledgeable friend. Traefik is responsible for implementing those resources and handling the actual traffic meaning the routing definitions aren’t tied to Traefik and the controller could be swapped without rewriting them.

# Why Longhorn for persistent storage?

Implemented Longhorn for persistent storage to allow for stateful pods to be able to move between nodes without losing data and thus keeping in line with the HA approach to the cluster by avoiding tying application storage to any individual node. Longhorn also provides replicated block storage within the cluster and allows for backups to be create which can be stored on the NAS. 

Restricted Longhorn to 2 replicas and set configuration to only create default storage disks on labelled nodes (worker nodes in this case). Avoids resource contention on control-plane nodes with etcd.

Node01 holds longhorn management processes & pods also. Initially implemented until resource utilisation of these can be confirmed before deploying onto remaining control-plane nodes. If low can be replicated across other control-plane nodes again keeping HA approach.

Longhorn uses node-local disks as storage, including existing filesystem rather than separate partition.

# Why Prometheus and Grafana (kube-prometheus-stack)?

Prometheus and Grafana were implemented to provide centralised dashboards for metrics across the cluster using industry standard tooling. The kube-prometheus-stack Helm chart was an easy entry point because it’s well documented and packaged. Prometheus is kept internal to the cluster and Grafana reaches it through its Kubernetes Service and thus Prometheus doesn’t need to be exposed. Grafana is exposed through Traefik with an HTTPRoute. Both use Longhorn-backed PVCs so their data isn’t tied to a particular node.

# Why move Pi-hole into the cluster?

Mostly because it’s a good workload to learn on - it’s a real service the whole network uses and it exercises MetalLB (a LoadBalancer Service at 192.168.1.243 serving DNS over TCP and UDP).

DHCP hands out Pi-hole (192.168.1.243) as the primary DNS server and the router (192.168.1.1) as the secondary. If Pi-hole is unavailable, clients fall back to the router’s own resolver which keeps name resolution working (without filtering) while the cluster is down.

# Why run Tailscale on the NAS?

Tailscale runs as a subnet router on the NAS rather than as an application within Kubernetes. This provides a single, centralised entry point for remote access to both the Kubernetes cluster and services running directly on the NAS, without needing to configure individual access mechanisms for each application.

Running the router independently of Kubernetes also means remote access to the cluster does not depend on the cluster itself being operational. This is useful for troubleshooting and maintaining the infrastructure if the cluster becomes unavailable.

The router advertises the home LAN subnet, with UFW restricting forwarded traffic to the services intended for remote access. Tailscale split DNS forwards queries for the private `.home` domain to Pi-hole, allowing existing service hostnames to resolve remotely.

This approach avoids exposing services directly to the public internet while keeping remote access configuration centralised and relatively simple to maintain.




