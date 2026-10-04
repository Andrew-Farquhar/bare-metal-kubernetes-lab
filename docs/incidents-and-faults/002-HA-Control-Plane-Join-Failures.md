# Incident Description:
- Date: 03/10/2026
- State: Resolved

# Summary:

During the initial build of the Kubernetes High Availablity control plane, the second control-plane node failed to join the cluster successfully.

The failure was caused by an incorrect HAProxy/API configuration. HAProxy and the Kubernetes API Server were both attempting to bind to port :6443 on the control-plane nodes, leading to conflicts and an unstable API Server on both the existing and joining node.

Following investigations of the kubelet and API server failures, the architecture was reconfigured so that:

- Keepalived provided the Kubernetes API VIP at 192.168.1.240
- HAProxy listened on 192.168.1.240:8443
- HAProxy forwarded TCP traffic to the control-plane API servers on :6443
- kube-apiserver continued to listen normally on :6443
- kubeadm's controlPlaneEndpoint was amended to 192.168.1.240:8443

The original cluster state was completely reset and rebuilt using the amended architecture. All three control-plane nodes proceeded to join successfully, followed by the two remaining worker nodes resulting in a cluster containing three HA control-plane nodes and two workers in a Ready state.

# Impact:

The incident prevented the planned HA control-plane build from completing. 

The first control-plane node was also impacted as etcd quorum issues from the failed join attempt cause etcd to on node01 (the first control-plane) to enter a crash-loop. This in turn caused node01's API server to enter a crash loop.

# Initial Architecture

The initial design attempted to expose the Kubernetes API through HAProxy while maintaining port 6443 for HAProxy and the API servers. The initial kubeadm configuration attempted to bind the API Server to the node's IP address on port 6443, with the expectation that this would avoid conflicts. It did not.

# Symptoms:

The second control-plane node repeatedly failed during:

[kubelet-start] Waiting for the kubelet to perform the TLS Bootstrap

Investigation showed that the kube-apiserver on the joining node was failing and that kubelet was unable to communicate reliably with the local API server.

The kube-apiserver was observed in CrashLoopBackOff, with connection attempts to:

192.168.1.193:6443

failing.

Additional investigation of the etcd and API server configuration confirmed that the control-plane components were not operating correctly under the original HAProxy arrangement.

# Root Cause:

The original architecture effectively required HAProxy and kube-apiserver to coexist on the same port:

HAProxy        :6443
kube-apiserver :6443

The subsequent bind-address workaround attempted to solve the symptom rather than the architectural problem abut had successfully allowed for the first control-plane to initialise. When a second control-plane attempted to join though, it inherited the bind-address configuration from node01. kubeadm join --control-plane builds node02's kube-apiserver manifest from that ConfigMap not from node02's local file. advertiseAddress is set per node in JoinConfiguration, but bind-address was not, so node02 received --bind-address=192.168.1.230. node02 has no interface with that address so kube-apiserver cannot bind and exits on startup and entered a CrashLoopBackOff state and nothing 

# Resolution & Recovery:

The architecture was changed so that HAProxy and kube-apiserver utilise different ports.

HAProxy operates as a TCP passthrough proxy, TLS termination is not performed by HAProxy.

The kubeadm configuration was simplified to:

```yaml
apiVersion: kubeadm.k8s.io/v1beta4 
kind: ClusterConfiguration 

controlPlaneEndpoint: "192.168.1.240:8443" 

networking: 
  podSubnet: "10.244.0.0/16"
```
The API server no longer required the previous bind-address configuration.

The affected control-plane nodes were reset and stale Kubernetes state was removed.

The first control-plane node was rebuilt using the corrected architecture.

Flannel was installed as the cluster CNI.

The second and third control-plane nodes were then joined through:

192.168.1.240:8443

The config for the second and third control-planes were also amended as during the failed join attempt it was observed that the ```InitConfiguration``` and ```ClusterConfiguration``` documents were ignored when joining. This meant that the remaining configurations were simplified to:
```yaml
apiVersion: kubeadm.k8s.io/v1beta4
kind: JoinConfiguration

discovery:
  bootstrapToken:
    apiServerEndpoint: "192.168.1.240:8443"
    token: "Join Token"
    caCertHashes:
      - "sha256:hash"


controlPlane:
  localAPIEndpoint:
    advertiseAddress: "192.168.1.193"
    bindPort: 6443
  certificateKey: "CA Key Hash"
```

Both successfully became Ready control-plane nodes. The two worker nodes were subsequently joined using the same HA API endpoint.

# Contributing Factors / Other Observations:

1. Port ownership was not considered early enough

The original design treated the VIP and API server endpoint as effectively the same thing.

The important distinction is:

controlPlaneEndpoint = stable endpoint clients use to reach the cluster
kube-apiserver :6443 = API server's local listening port
HAProxy :8443 = proxy entry point
2. A configuration workaround obscured the underlying problem

The API server bind-address configuration was introduced to work around the port conflict.

This increased complexity without addressing the actual architectural issue.

3. HAProxy was running on the control-plane nodes

Because HAProxy and kube-apiserver shared the same hosts, their listening ports needed to be explicitly separated.

# Lessons Learned:

- Keep the cluster endpoint separate from the API Server Port. In a HA configuration the Kubernetes endpoint and API Server ports do not need to be the same.
- Fix architecture rather than chasing symptoms. The bind-address workaround added complexity.
- Rebuilding can be faster than repairing a broken cluster state.
- kubeadm init and kubeadm join use different configuration objects. InitConfiguration and ClusterConfiguration are used during initial cluster creation, while control-plane joins use JoinConfiguration.




