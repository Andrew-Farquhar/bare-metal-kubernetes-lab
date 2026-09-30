# Kubernetes cluster
- 5 × Dell OptiPlex 9020M
- Debian 13
- 8GB RAM per node (LDDR3)
- 128GB SSD per node
- Gigabit Ethernet
- Unmanaged TP-Link TL-SG108 switch

# Network Attached Storage

- Intel i5 6th Gen
- Ubuntu Server
- 128GB SSD for root file system
- 3 x 6TB SAS Drives (ZFS, RAIDZ1)
- AMD RX560
- 28GB DDR3

Topology:

```mermaid
graph TD
    Internet(Internet)
    ISPRouter(ISP Router)
    Switch1("Gigabit unmanaged<br>switch")
    
    Internet --> ISPRouter
    ISPRouter --> Switch1
    
    NAS(NAS)
    K8sSwitch("K8s Switch<br>(Gigabit<br>Unmanaged)")
    
    Switch1 --> NAS
    Switch1 --> K8sSwitch
    
    ZFS{"ZFS<br>Storage"}
    Media{"Media<br>Services"}
    
    NAS --> ZFS
    NAS --> Media
    
    KubeCluster(Kube Cluster)
    K8sSwitch --> KubeCluster
    
    Node1(K8s Node1)
    Node2(K8s Node2)
    Node3(K8s Node3)
    Node4(K8s Node4)
    Node5(K8s Node5)
    
    KubeCluster --> Node1
    KubeCluster --> Node2
    KubeCluster --> Node3
    KubeCluster --> Node4
    KubeCluster --> Node5
    
    ControlWorkers(Control Plane + Workers)
    WorkersOnly(Workers)
    
    Node1 --> ControlWorkers
    Node2 --> ControlWorkers
    Node3 --> ControlWorkers
    Node4 --> WorkersOnly
    Node5 --> WorkersOnly
    
    ControlWorkers ----> ZFS
```
