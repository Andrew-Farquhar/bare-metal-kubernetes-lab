# Why Debian 13?

Debian 13 was installed as the base OS for the Kubernetes nodes to provide a minimal but stable Linux environment while allowing the cluster components to be configured manually for learning purposes. Purpose built 'Kubernetes' Linux distributions were considered, however, these typically include out of the box configurations that would have hindered learning. 
Given Debian's reputation for reliability, this distribution also provides some assurance that the OS is less likely to be the root cause of faults. 

# Why one filesystem? 

The nodes are configured to use one filesystem as opposed to separate partitions for /var and /srv. This decision may be reversed in future iterations but for the moment this configuration provides a Linux environment that is familiar, allowing for deeper focus on Kubernetes. 
