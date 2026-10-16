# Incident: Pi-Hole DNS Connectivity Failure following redeployment

## Incident Description

- **Date:** 15/10/2026
- **State:** Resolved

## Summary

A change to Pi-Hole's `values.yaml` and subsequent redeployment using Helm led to the pod being recreated on a new node (`node01`). As a result of Pi-Hole's configuration at the time, local-DNS traffic was not able to be passed to the new node carrying the Pi-Hole pod.

## Impact

Describe the effect on the cluster and its services.

- **Affected service(s):** Local DNS Resolution & DNS Query Filtering
- **User impact:** Application webUIs for apps running in the cluster were unreachable. Ads and Telemetry DNS queries were successfully resolving as DNS had failed over to the ISP router's default.
- **Duration:** ~30 minutes

## Initial Architecture

Pi-Hole was deployed using Helm and a custom `values.yaml` file. When first deployed, Pi-Hole was successfully accessible on `192.168.1.241` for WebUI access and `192.168.1.243` for DNS queries from LAN devices, however, this was luck rather than design. The `values.yaml` did not specify an `externalTrafficPolicy` setting. The Helm chart defaulted this to `Local`.

## Symptoms

Once the change was applied to adjust the values file for Pi-Hole (not related to this incident), the pod was redeployed. To gauge the success of the change, access to the WebUI was tested. `pihole.home` did not resolve leading to a suspicion that the Pi-Hole pod's local DNS records had not survived recreation. A quick edit to the client's `/etc/hosts` file to add this URL provided access to the WebUI where it was observed that there were no incoming DNS queries to the service.

## Root Cause

Due to the default value for `externalTrafficPolicy` being set to `Local` by the Helm chart used to install Pi-Hole. However, 3 of the nodes in cluster (the control-plane + workers) hold a label `node.kubernetes.io/exclude-from-external-load-balancers`. 

The impact of this is that MetalLB cannot advertise the IP address from these nodes and this is compounded by the service preventing traffic being forwarded to Pi-Hole unless the endpoint is local. When the pod was redeployed as part of the upgrade, it was recreated on ```node01``` (previously on ```node05```), leading to the prevention of connectivity between the node advertising the IP and the Pi-Hole pod.

## Resolution & Recovery

Once it had been determined that DNS queries were not reaching the new Pi-Hole pod, the investigation turned to confirming that the pod was healthy and that the service was still using the LoadBalancer IP of `192.168.1.243`.

This was confirmed using:

```bash
kubectl get pods,svc -n apps
```

Connectivity was then tested for DNS queries directly to the LoadBalancer IP:

```bash
dig @192.168.1.243 google.com
```

This failed and indicated that although the pod and IP were healthy, the traffic was not reaching the pod.

MetalLB's address pool was checked to ensure that `192.168.1.243` was still included and confirmed that it was present.

MetalLB's speaker logs were reviewed but all looked reasonable and healthy, however, it clearly showed that the IP had not been announced on `node01`. A further check was run to check the nodes as the Pi-Hole pod was now running on a control-plane + worker node:

```bash
kubectl get nodes --show-labels
```

This revealed that the control-plane nodes very clearly had a label:

`node.kubernetes.io/exclude-from-external-load-balancers`

The Pi-Hole service was then inspected using:

```bash
kubectl describe svc pihole-dns -n apps
```

This showed that `externalTrafficPolicy` was set to `Local`.

Recognising that this configuration likely meant that Pi-Hole was expecting MetalLB to announce the IP on the local node but MetalLB had no way to execute this given the label present on the control-plane + worker nodes, the following command was run to set the `externalTrafficPolicy` to `Cluster`:

```bash
kubectl patch svc pihole-dns -n apps -p '{"spec":{"externalTrafficPolicy":"Cluster"}}'
```

Once applied, a review of the Pi-Hole WebUI showed that DNS queries were now reaching the pod. This configuration was successful as it allowed for traffic from any node to be routed to the pihole-dns service, as opposed to the default of only allowing this from a node local to the Pi-Hole pod.

To ensure this setting persisted, the ```values.yaml``` for Pi-Hole was edited to include this and another Helm upgrade was carried out. Given that the current configuration matched the updated values, Helm did not redeploy Pi-Hole.


## Lessons Learned

- Layered troubleshooting: Learned the importance of checking the pod and Service first, then expanding the investigation to endpoints, external connectivity, MetalLB and node configuration when the initial checks appeared healthy.

- Understanding Service traffic policies: Gained a better understanding of the difference between externalTrafficPolicy: Local and Cluster, and how the choice affects external traffic routing within the cluster.

- Configuration and node topology: Learned how Kubernetes node configuration and Service settings can interact to produce unexpected behaviour, even when the application itself is healthy.

- Following evidence: The investigation demonstrated how individual command outputs and observations can be used together to narrow down a problem and identify a suitable corrective action.

