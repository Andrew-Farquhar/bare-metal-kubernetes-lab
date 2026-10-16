# Fault: Pi-Hole Client Visibility Disrupted

**Date:** 16/10/2026

### Observation

Following a change to Pi-Hole's `externalTrafficPolicy` to `Cluster`, DNS filtering and local DNS records were successfully resolving, however, Pi-Hole's dashboard was unable to list the clients that the queries originated from.

This was due to traffic being forwarded between nodes, resulting in Pi-Hole observing 50k+ queries from `10.244.3.0`. Following a quick investigation this was identified as the Flannel subnet on Node05, while Pi-Hole was running on Node01.

This led to the realisation that Pi-Hole cannot differentiate clients when inbound DNS traffic to the cluster on `192.168.1.243` (MetalLB's IP for Pi-Hole) is being forwarded across the cluster. The decision was therefore made to restore ```externalTrafficPolicy``` to ```Local``` and restrict Pi-Hole to Node04 or Node05, where MetalLB can advertise the IP.

### Change

Pi-Hole's `values.yaml` was modified to include an `affinity` configuration block:

```yaml
affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
        - matchExpressions:
            - key: kubernetes.io/hostname
              operator: In
              values:
                - node04
                - node05
```

The `serviceDns` configuration was also amended to:

```yaml
serviceDns:
  mixedService: true
  type: LoadBalancer
  externalTrafficPolicy: Local # Influences MetalLB's election for advertising the IP to follow local endpoints for Pi-Hole, ideally keeping the speaker and Pi-Hole on the same local node.
  annotations:
    metallb.io/loadBalancerIPs: "192.168.1.243"
```

The deployment was then upgraded using Helm.

### Outcome

Pi-Hole was successfully scheduled on Node04, and MetalLB's speaker on Node04 began advertising the IP address for DNS traffic. The Pi-Hole WebUI began showing active clients and their legitimate IP addresses once again.

The failover mechanism between Node04 and Node05 was then tested by rebooting Node04. Pi-Hole successfully rescheduled onto Node05, and MetalLB also advertised the IP address from Node05. The WebUI was checked again, and client visibility remained functional.
