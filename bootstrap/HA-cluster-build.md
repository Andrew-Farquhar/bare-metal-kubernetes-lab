# Kubernetes HA Cluster — Final Build Procedure

---

# 1. Create the Initial Cluster on node01

A `ClusterConfiguration` YAML was created on node01.

This YAML was only used for the initial `kubeadm init`.

```yaml
apiVersion: kubeadm.k8s.io/v1beta4
kind: ClusterConfiguration

controlPlaneEndpoint: "192.168.1.240:8443"

networking:
  podSubnet: "10.244.0.0/16"
```

The cluster was initialised with:

```bash
sudo kubeadm init --config kubeadm-config.yaml
```

The important configuration here was:

```text
controlPlaneEndpoint: 192.168.1.240:8443
```

This defines the stable API endpoint for the cluster through the Keepalived VIP and HAProxy.

After initialisation `kubectl` was configured for the `kube` user.

The API endpoint was verified with:

```bash
kubectl cluster-info
```

---

# 2. Install the CNI

Flannel was installed once the initial control-plane was operational:

```bash
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
```

The cluster uses:

```text
Pod CIDR: 10.244.0.0/16
```

The first node was allowed to become Ready before proceeding.

---

# 3. Obtain the Control-Plane Join Credentials

Additional control-plane nodes require:

1. A bootstrap token
2. The CA certificate hash
3. A certificate key for distributing the control-plane certificates

A fresh bootstrap token and CA hash were generated with:

```bash
sudo kubeadm token create --print-join-command
```

The control-plane certificate key was obtained with:

```bash
sudo kubeadm init phase upload-certs --upload-certs
```

The output provides the certificate key required when joining additional control-plane nodes.

---

# 4. Join node02 as a Control-Plane

Control-plane joins used a different YAML configuration from the initial cluster bootstrap.

The initial ClusterConfiguration was not reused for the join.

A JoinConfiguration was created on node02:

```yaml
apiVersion: kubeadm.k8s.io/v1beta4
kind: JoinConfiguration

discovery:
  bootstrapToken:
    apiServerEndpoint: "192.168.1.240:8443"
    token: "<join-token>"
    caCertHashes:
      - "sha256:<CA-hash>"

controlPlane:
  localAPIEndpoint:
    advertiseAddress: "192.168.1.193"
    bindPort: 6443
  certificateKey: "<certificate-key>"
```

The join was performed with:

```bash
sudo kubeadm join --config kubeadm-config.yaml
```

Once complete node02 was checked from node01:

```bash
kubectl get nodes
```

---

# 5. Join node03 as a Control-Plane

The same JoinConfiguration structure was used for node03.

The node-specific advertised address was changed to:

```yaml
controlPlane:
  localAPIEndpoint:
    advertiseAddress: "192.168.1.179"
    bindPort: 6443
  certificateKey: "<certificate-key>"
```

The same cluster API endpoint, bootstrap token, CA hash and certificate key were used.

The join was performed with:

```bash
sudo kubeadm join --config kubeadm-config.yaml
```

The cluster was then checked:

```bash
kubectl get nodes
```

At this point all three control-plane nodes were operational.

---

# 6. Generate the Worker Join Command

Workers do not require the control-plane certificate key.

A fresh worker join command was generated from node01:

```bash
sudo kubeadm token create --print-join-command
```

This produced:

```bash
kubeadm join 192.168.1.240:8443 \
  --token <token> \
  --discovery-token-ca-cert-hash sha256:<CA-hash>
```

The same command can be used for both workers while the token remains valid.

---

# 7. Join node04 & node05

The worker join command was run directly on node04:

```bash
sudo kubeadm join 192.168.1.240:8443 \
  --token <token> \
  --discovery-token-ca-cert-hash sha256:<CA-hash>
```

No certificateKey is required for a worker.

Flannel automatically deployed its node-specific DaemonSet pod after the node joined.

This was repeated on node05.

# 8. Verify the Complete Cluster

From node01:

```bash
kubectl get nodes
```

Final state:

```text
NAME     STATUS   ROLES
node01   Ready    control-plane
node02   Ready    control-plane
node03   Ready    control-plane
node04   Ready    worker
node05   Ready    worker
```

All five nodes were running Kubernetes v1.37.1.

## Final Result

The cluster was successfully built with:

* 3 HA control-plane nodes
* 2 worker nodes
* Keepalived API VIP
* HAProxy API load balancing
* TCP passthrough to the Kubernetes API servers
* Flannel CNI
* containerd runtime
* Kubernetes v1.37.1

The important kubeadm configuration distinction is:

| Purpose                        | Configuration                                 |
| ------------------------------ | --------------------------------------------- |
| Initial cluster creation       | `ClusterConfiguration`                        |
| Additional control-plane nodes | `JoinConfiguration` + `controlPlane`          |
| Worker nodes                   | `JoinConfiguration` / standard `kubeadm join` |

The final API endpoint used by all joins was:

```text
192.168.1.240:8443
```
