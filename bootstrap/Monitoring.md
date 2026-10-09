## Monitoring

### Purpose
Prometheus and Grafana were implemented to provide centralized dashboards for monitoring metrics across the Kubernetes cluster using industry standard tooling and an easy entry point into monitoring via well documented and packaged deployment options.

### Architecture
Node Exporter / kube-state-metrics / kubelet → Prometheus → Grafana

Prometheus-Node-Exporter is deployed on each node. This pod exposes metrics from the underlying OS to provide CPU/Memory/Disk metrics of the node itself.
kube-state-metrics provides metrics from Pods/Services/Deployments at the Kubernetes Layer
kubelet/cAdvisor provides container runtime/resource usage
Prometheus scrapes metrics from all three of the above services and stores them.
Grafana queries Prometheus for these metrics and provides the web-based interface used to visualise them through dashboards.

### Deployment
- kube-prometheus-stack:
kube-prometheus-stack was deployed via helm charts. 
The kube-prometheus-stack was added to the helm repo. The default values were then copied to a local file to inspect both Grafana and Prometheus' values. This allowed for values specific to the cluster, such as PVC values to be provided to the Grafana and Prometheus pods. The chart's CRD upgrade job was enabled via these values to handle the Prometheus Operator CRDs during installation. This was necessary because manually applying the generated CRDs encountered Kubernetes' metadata annotation size limit.
- PVCs in this cluster are backed by Longhorn storage. Grafana was provided with 10Gi of block storage, Prometheus was provided with 20Gi.
- Once configured the helm chart was deployed:

  ```bash helm install monitoring prometheus-community/kube-prometheus-stack --namespace monitoring --create-namespace```
  
- Grafana exposed through Traefik/Gateway API. An HTTPRoute was configured and applied to point grafana at Traefik. Traefik was then exposed via NodePort.
- Prometheus was kept internal to the cluster. Grafana connects to Prometheus through its Kubernetes Service, meaning Prometheus does not need to be externally exposed.

### What is being monitored
- Node/resource metrics
- Kubernetes object/state metrics
- Container metrics where exposed
- Alerts/events where applicable

### Grafana
Grafana was configured with Prometheus as its data source. This allows Grafana to query the metrics collected by Prometheus using PromQL. Rather than building dashboards manually, an existing Kubernetes monitoring dashboard was imported to provide an initial overview of cluster and pod health.

### Observations
- Node metrics are available
- Pod/state metrics are available
- Some dashboard panels are empty because the underlying condition doesn't exist
- Some metrics depend on additional runtime/resource metrics being exposed
- An empty panel isn't necessarily a monitoring failure

