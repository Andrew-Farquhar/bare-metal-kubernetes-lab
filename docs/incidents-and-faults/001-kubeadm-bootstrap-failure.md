# Incident Description:

02/10/2026

When attempting to bootstrap the first control-plane on node01, the initialization failed with the following warnings:

- [WARNING ContainerRuntimeVersion] - must update your container runtime to a version that supports the CRI method RuntimeConfig.
- [ERROR FileContent--proc-sys-net-ipv4-ip_forward]: /proc/sys/net/ipv4/ip_forward contents are not set to 1.

Kubernetes by design attempted to fall back to cgroupDriver from the kubelet config, however, this in of itself did not cause the initialisation to fail.
Kubernetes aborted the initialisation once it encountered the IPv4 forwarding error. Kubernetes expects IPv4 forwarding to be enabled as a per-requisite as this facilitates the nodes forwarding traffic between network interfaces/networks.

# Resolution:

IPv4 forwarding was enabled using the following command:
```bash
sudo sysctl -w net.ipv4.ip_forward=1
```
This was then made persistent by editing /etc/sysctl.d/kubernetes.conf and adding "net.ipv4.ip_forward = 1".

This resolved the fatal error and would have allowed for the bootstrap to continue. At this point the decision was taken to address the containerd/CRI warning observed.
Upon investigation it was observed that the containerd package installed directly from the Debian repository was an older version (1.7.24) and did not implement the CRI operation (RuntimeConfig) that Kubernetes was expecting. Kubernetes was able to fall back to the kubelet's cgroup configuration with this version of containerd, however, this fallback was not a long term solution and would have introduced a compatibility issue with future Kubernetes releases.
To remedy this the Docker repositories were added to apt, allowing access to the most up to date containerd packages. Containerd was upgraded to version 2.3.6. 
Once the latest containerd package was installed, the configuration was regenerated and the service was restarted.

Upon retry of the kubeadm init command, no errors or warning were observed and the control-plane successfully initialised!

# Learnings:

- Kubernetes has prerequisites that kubeadm will validate during bootstrap
- A warning won't necessarily cause the current operation fail but can indicate an upcoming issue. Errors will likely abort the operation.
- Container runtimes interact with Kubernetes via the CRI
- Kubernetes' control-plane bootstrap is dependent on the underlying host's network config.

