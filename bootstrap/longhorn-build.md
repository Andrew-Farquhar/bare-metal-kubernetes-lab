# Longhorn Build

## Purpose

Introduced Longhorn to provide persistent storage for Kubernetes workloads.

The aim is to allow for stateful pods to move between nodes without being tied to the local storage of any particular Kubernetes node. Longhorn provides block storage to the cluster, allowing application data to be stored in a persistentVolume to remain available if a node hosting the application fails.

## Storage Architecture

Longhorn management components are currently running on:
- node01
- node04
- node05

Longhorn storage is only provided by:
- node04
- node05

Node01 runs Longhorn management components but does not have a Longhorn storage disk configured as it is a control-plane node.

The remaining control-planes (node02, node03) do not currently run Longhorn components but may in future to remain inline with the HA approach to the cluster.

## Prerequisites

Longhorn requires several packages and kernel functionality on the Kubernetes nodes.

The following packages were installed on all five nodes:

`sudo apt install open-iscsi nfs-common cryptsetup dmsetup`

open-iscsi provides the iSCSI functionality used by Longhorn to attach its volumes.

The iSCSI service was enabled and checked:

`sudo systemctl enable --now iscsid
sudo systemctl status iscsid`

The dm_crypt kernel module was also loaded:

`sudo modprobe dm_crypt`

To make this persistent across reboots:

`echo dm_crypt | sudo tee /etc/modules-load.d/longhorn.conf`

The Longhorn prerequisites were then present across the cluster.

## Preparing the Nodes

Longhorn was restricted to node04 and node05 for storage. This decision was taken to ensure that there was no resource contention between the control-plane and the storage components. etcd was of particular concern for this.

The nodes were labelled:

`kubectl label node node04 node.longhorn.io/create-default-disk=true`

`kubectl label node node05 node.longhorn.io/create-default-disk=true`

and the following configuration was changed from the default configuration for Longhorn to ensure default storage disks were only created on labelled nodes:

```yaml create-default-disk-labeled-nodes: "true"```

This prevents Longhorn from automatically creating storage disks on the other Kubernetes nodes.

The existing filesystem was used rather than creating a separate partition or filesystem for Longhorn.

The Longhorn storage path on both nodes is:

/var/lib/longhorn/

The disks are the existing 128 GB SanDisk X400 SATA SSDs.

## Configuring Longhorn

Longhorn version 1.13.0 was used.

The installation manifest was edited before applying it.

The default replica count was changed to two:

numberOfReplicas: "2"

The replica count determines how many copies of a Longhorn volume are maintained.

With two replicas, a volume stored using Longhorn has two copies of its data distributed across the available storage nodes.

## Installing Longhorn

The Longhorn installation manifest was applied using:

`kubectl apply -f longhorn.yaml`

The Longhorn namespace and resources were then created by Kubernetes.

The Longhorn components were checked with:

`kubectl -n longhorn-system get pods -o wide`

Longhorn's node resources were checked with:

`kubectl -n longhorn-system get nodes.longhorn.io`

This showed node01, node04 and node05 as Longhorn nodes.

The storage configuration on the nodes was inspected with:

`kubectl -n longhorn-system get nodes.longhorn.io node04 -o yaml`

`kubectl -n longhorn-system get nodes.longhorn.io node05 -o yaml`

Both storage nodes reported a healthy default disk.

Node01 had no Longhorn storage disk configured.

## Testing Persistent Storage
Testing Persistent Storage

A 1 GiB PVC was created to test the Longhorn storage.

```yaml apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-pvc
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: longhorn
  resources:
    requests:
      storage: 1Gi
```

The PVC was checked with:

`kubectl get pvc`

The PVC entered the Bound state.

The resulting PV was inspected with:

`kubectl get pv`

The PV used the Longhorn CSI driver:

driver.longhorn.io

The PV also showed the Longhorn volume configuration, including two replicas.

A BusyBox Pod was created to mount the PVC:

```yaml apiVersion: v1
kind: Pod
metadata:
  name: test-pod
spec:
  containers:
    - name: writer
      image: busybox
      command: ["sh", "-c", "date >> /data/log.txt; sleep 3600"]
      volumeMounts:
        - name: data
          mountPath: /data
  volumes:
    - name: data
      persistentVolumeClaim:
        claimName: test-pvc
```

The Pod was scheduled onto node04.

Before the Pod mounted the volume, the Longhorn volume existed but was detached.

Once the Pod started using the PVC, Longhorn attached the volume to node04 and started the Longhorn engine.

The volume then showed:
```
STATE       attached
ROBUSTNESS  healthy
NODE        node04
```

Both replicas were running:
```
node04   running
node05   running
```

Data was written to the volume:

`kubectl exec test-pod -- cat /data/log.txt`

The file contained multiple entries, including:

`Longhorn replication test Wed Oct  7 12:30:03 UTC 2026`

This confirmed that the Pod was successfully using the Longhorn-backed PersistentVolume.

# Replica Test

The Longhorn volume showed two replicas:

Replica 1 -> node04
Replica 2 -> node05

The two replicas are maintained by Longhorn at the block-storage level.

The underlying replica directories were inspected on the storage nodes. These were not treated as normal application data directories because the replica data is part of Longhorn's internal storage format.

The application data should therefore be accessed through the mounted PVC rather than directly through /var/lib/longhorn/.

# Failure and Recovery Test

A failure test was performed by powering off node05 while the Longhorn volume was attached to node04.

The purpose of the test was to verify that losing one of the two storage nodes would not make the application data unavailable.

Before the failure, the volume was healthy and had two running replicas.

Node05 was then powered off.

During the failure, the Pod remained available on node04 and the existing data remained readable through the mounted PVC.

The volume therefore remained usable despite one of its two replicas being unavailable.

Node05 was then powered back on.

Once the node returned to the cluster, Longhorn detected the storage node and recovered the replica.

The final state showed:
```
STATE       attached
ROBUSTNESS  healthy
NODE        node04
```

Both replicas were running again:
```
node04   running
node05   running
```

The data was still readable from the Pod:

`kubectl exec test-pod -- cat /data/log.txt`

All previously written entries were still present.

This confirmed that the Longhorn volume remained available during the loss of one storage node and that the second replica recovered when the failed node returned.

# Final State

The final Longhorn configuration is:

| Item | Configuration |
|---|---|
| Longhorn version | 1.13.0 |
| Storage nodes | node04, node05 |
| Replica count | 2 |
| Storage path | `/var/lib/longhorn/` |
| Filesystem | Existing filesystem / ext4 volumes |
| Storage disk | 128 GB SanDisk X400 SSD per node |
| Default disk creation | Labelled nodes only |
| Longhorn management | node01, node04, node05 |
| Backup target | Not configured |
| Default StorageClass | Longhorn |

The cluster currently has two independent copies of Longhorn volume data across node04 and node05.

Longhorn management components are currently present on node01, node04 and node05. Management components may later be spread across the remaining control-plane nodes after resource utilisation has been assessed.

# Lessons Learned
- Longhorn storage and Longhorn management are separate concepts.
- A node can run Longhorn management components without providing storage.
- PVCs request storage from Kubernetes; the Longhorn CSI driver handles the connection between Kubernetes storage objects and Longhorn volumes.
- A Longhorn volume is backed by a Longhorn engine and one or more replicas.
- Two replicas provide redundancy across the two storage nodes.
- The replicas are block-level storage and should not be treated as normal directories containing application files.
- Kubernetes decides where the Pod runs, while Longhorn handles where the volume replicas are stored.
- Replication provides availability against storage-node failure but is not a replacement for backups.
- The NAS can be used as a future Longhorn backup target.
- The failure test demonstrated that application data remained available when one Longhorn storage node was unavailable.
