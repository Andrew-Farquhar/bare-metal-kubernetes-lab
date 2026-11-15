# Immich Initial Ingestion – Resource Pressure

## Overview

During the initial ingestion of media (photos and videos) from the first client device to utilize Immich, around 4000+ images and videos were added to the backup/ingestion queue for Immich. After ~200 images were processed the error rate for backups increased significantly, processing significantly slowed and eventually the application stopped responding entirely.

## Symptoms

- Node05 (worker) eventually unresponsive to pings and SSH attempts
- Immich Server and Immich Machine Learning pods continually restarting
- Node05 pinned at 98% CPU and Memory utilization, with Immich Server and Machine Learning pods consuming more memory than was available on the node
- All other apps on cluster unresponsive
- All apps on cluster scheduled to Node05 at time of incident
- Continual restarts of the culprit pods allowed for Node05 to recover just enough to avoid being marked as 'notReady' by controller-manager.

## Investigation

- Reviewed Grafana to gather resource metrics and identify current pressures
- Inspection of node and pods using ```kubectl``` identified multiple pod restarts due to failed liveness probes
- All application pods on cluster were scheduled on Node05
- Grafana graphs identified Immich Server consuming 5Gi of memory (8Gi available on node), with Immich Machine Learning consuming 3.3 CPU cores (4 available on node)
- Database and other key Immich components showed healthy. All other nodes in cluster also healthy at time of investigation.
- Immich default Helm values and custom values used to deploy Immich compared, identified that no resource requests or limits in place.


## Resolution

- Resource requests and limits adjusted. Initially only for Immich. CPU requests set to 2.5 for both Immich server and Immich Machine Learning components to ensure scheduler always attempts to schedule on separate nodes and reduces quantity of neighbouring pods on nodes hosting these components without setting nodeAffinity or nodeSelector rules.
- Once implemented scheduler separated the components onto separate nodes
- Video transcoding settings on Immich disabled to reduce CPU utilization when ingesting videos. Not required for use case for application at this time.
- Initially Video Transcoding was disabled which significantly reduced memory and CPU consumption of the Immich Server pod. Ingestion queue was allowed to process before further changes to resource requests/limits were made. The latter decision was taken to attempt to reduce impact to the application's processing itself and to allow for some BAU running of the application on the cluster before determining resource values.

## Outcome

- Ingestion queue eventually drained following change to transcoding settings
- CPU and memory usage return to acceptable levels
- Cluster return to normal operation

## Lessons Learned

- No initial resource allocations were made when deploying the application.
- Up to this point no resource allocations were made for any applications on the cluster. This lead to all apps being scheduled to a single node.
- Resource requests play an important role in how Kubernetes schedules workloads. By setting appropriate CPU requests, the scheduler was able to distribute the Immich Server and Machine Learning components across separate nodes without requiring explicit node affinity or node selectors.
- Optional application functionality such as video transcoding, can introduce additional resource demands. Disabling functionality that wasn't required for the intended use case helped reduce pressure on the cluster.

