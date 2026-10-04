# Incident Description:

**Date:** 02/10/2026
**Status:** Resolved
**Affected Node:** `node01`
**Component:** Kubernetes Control-Plane Bootstrap
When attempting to bootstrap the first control-plane on node01, the initialization failed with the following warnings:

# Summary:

When attempting to bootstrap the first control-plane on `node01`, the initialisation failed with the following warnings/errors:

* `[WARNING ContainerRuntimeVersion]` — must update your container runtime to a version that supports the CRI method `RuntimeConfig`.
* `[ERROR FileContent--proc-sys-net-ipv4-ip_forward]` — `/proc/sys/net/ipv4/ip_forward` contents are not set to `1`.

Kubernetes detected both issues during its pre-flight checks. The containerd/CRI issue was reported as a warning and Kubernetes was able to fall back to the `cgroupDriver` configured in the kubelet. This warning did not cause the initialisation to fail.

The IPv4 forwarding configuration was the issue that caused `kubeadm init` to abort. Kubernetes requires IPv4 forwarding to be enabled as a prerequisite, as this facilitates nodes forwarding traffic between network interfaces/networks.

Therefore, the IPv4 forwarding error was the immediate cause of the failed bootstrap while the containerd/CRI warning was a separate compatibility issue that was subsequently addressed.


---

## Bootstrap Sequence



The initial kubeadm init was attempted on node01 after the required Kubernetes packages and containerd had been installed.

The pre-flight checks identified two issues:

An IPv4 forwarding configuration error, which caused the bootstrap to abort.

A containerd/CRI compatibility warning, which did not prevent the bootstrap from continuing but indicated that the installed containerd version was not fully compatible with the expected CRI functionality.

The IPv4 forwarding issue was resolved first, allowing the bootstrap to proceed.

The containerd warning was then investigated and the decision was taken to upgrade containerd from version 1.7.24 to 2.3.6 rather than rely on the kubelet cgroup configuration fallback.

After the containerd upgrade, its configuration was regenerated and the service restarted.

kubeadm init was then retried and completed successfully, with the first control-plane on node01 fully initialised.
## Resolution

### 1. IPv4 Forwarding

IPv4 forwarding was enabled using:

```bash
sudo sysctl -w net.ipv4.ip_forward=1
```

This was then made persistent by editing:

```text
/etc/sysctl.d/kubernetes.conf
```

and adding:

```text
net.ipv4.ip_forward = 1
```

This resolved the fatal error and would have allowed the bootstrap to continue.

### 2. Containerd / CRI Compatibility

At this point, the decision was taken to address the containerd/CRI warning that had also been observed.

Upon investigation, it was observed that the containerd package installed directly from the Debian repository was an older version (`1.7.24`) and did not implement the CRI operation (`RuntimeConfig`) that Kubernetes was expecting.

Kubernetes was able to fall back to the kubelet's cgroup configuration with this version of containerd. However, this fallback was not considered a long-term solution and would have introduced a compatibility issue with future Kubernetes releases.

To remedy this, the Docker repositories were added to `apt`, allowing access to the most up-to-date containerd packages.

Containerd was upgraded to version `2.3.6`.

Once the latest containerd package was installed, the configuration was regenerated and the service was restarted.

### 3. Successful Bootstrap

Upon retrying the `kubeadm init` command, no errors or warnings were observed and the control-plane successfully initialised.

**Incident resolved.**

---

## Learnings

* Kubernetes has prerequisites that `kubeadm` will validate during bootstrap.
* A warning won't necessarily cause the current operation to fail, but can indicate an upcoming issue. Errors will likely abort the operation.
* Container runtimes interact with Kubernetes via the CRI.
* Kubernetes' control-plane bootstrap is dependent on the underlying host's network configuration.
