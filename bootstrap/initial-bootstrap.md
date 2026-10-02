# Node Preparation:

- System updated
- Permanently disabled swap memory. The /etc/fstab entry was commented out to ensure configuration was persistent between boot cycles.
``` bash
sudo swapoff -a
```
``` bash
sudo nano /etc/fstab/
```
- Installed containerd from Docker repository:
```bash
sudo apt update
sudo apt install -y apt-transport-https ca-certificates curl gpg
sudo mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  trixie stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install containerd.io
```
- Installed nerdctl:
```bash
wget https://github.com/containerd/nerdctl/releases/download/v2.4.0/nerdctl-2.4.0-linux-amd64.tar.gz
sudo tar -C /usr/local/bin -xzf nerdctl-2.4.0-linux-amd64.tar.gz nerdctl
```
- Installed kubectl, kubeadm & kubelet from the official Kubernetes v1.37 repository:
```bash
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.37/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.37/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt update
sudo apt install kubeadm kubelet kubectl
sudo apt-mark hold kubelet kubeadm kubectl
```
apt-mark hold for packages intention to prevent version drift.

- Enabled br_netfilter and made persistent providing visibility of packets crossing bridges to netfilter:
```bash
sudo modprobe br_netfilter
```
```bash
echo br_netfilter | sudo tee /etc/modules-load.d/kubernetes.conf
```

- Enabled IPv4 forwarding and made persistent by editing /etc/sysctl.d/kubernetes.conf; allowing traffic/routing between pods:
```
sudo sysctl -w net.ipv4.ip_forward=1
```


# Control Plane Bootstrap:

- Initialised the Kubernetes control plane using kubeadm init, specifying the pod network CIDR used by Flannel:
```bash
sudo kubeadm init --pod-network-cidr=10.244.0.0/16
```
- Configured kubectl to communicate with the newly initialised cluster using the generated admin.conf

- Installed Flannel as the cluster CNI:
```bash
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
```
- Verified that the Flannel pod was running and that the control-plane node had converted from NotReady to Ready (exciting moment!)
- Verified that full suite of Kubernetes system pods were running correctly.

# Result:

node01 is operating as a healthy Kubernetes control-plane node.

Next step is to join the designated worker nodes to the cluster using ```kubeadm join```

  
