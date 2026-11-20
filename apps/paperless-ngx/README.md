# Paperless-ngx Deployment

## 1. Overview

Paperless-ngx is a community-supported open-source document management system that transforms your physical documents into a searchable online archive. This has been added to the suite of applications running in the cluster to provide a handy way of ingesting and organizing paper documents and storing them in a reasonably reliable ZFS backed pool. The reality is that the easier option would be to run this directly on the NAS in docker, however, the challenge of deploying a multi-component application without a helm chart was too alluring. 

## 2. Architecture and Design

- The deployment involved making use of hand crafted Services, PVC, PV and Deployment manifests alongside a CNPG deployed PostgreSQL instance.
- The application is dependent on a database (flavours vary, postgreSQL was used in this instance) and a redis key-value store instance.
- Persistent storage is handled via longhorn backed PVCs for application data and a PersistentVolume on the NAS via NFS.
- Longhorn was chosed to handle Application and Data storage for performance and redundancy/resilience (via replication and daily backups). The documents themselves are stored on the NAS via an NFS share which has vastly more capacity and is backed by a monitored ZFS RAIDZ1 pool.
- The application is exposed via a service and an HTTPRoute - The service itself is very simple, using clusterIP. This service allows for Traefik to route traffic to the application. 

## 3. Deployment

- In total 9 Manifests were created.
- Deployment was carried out manually, with each manifest being applied using ```kubectl apply -f xyz.yaml```. PVCs and PVs were deployed first, followed by Services & the HTTPRoute. Dependencies were then deployed (Redis, Database), followed by the application server itself.
- Credentials and sensitive information are stored in Secrets. 
- The Database and Redis instance are exposed to the application server via services. 

## 4. Issues and Troubleshooting

- **Longhorn Capacity:** When initially deployed, the pod remained in pending. Further investigation revealed that Longhorn had no further schedulable capacity. Longhorn's reserves were reduced to allow for the PVC to bind. 
- **PVC binding:** A minor mistake in the media PVC's configuration (volumeName) lead to an incorrect PV being referenced. Corrected once noticed during deployment following a crashloop in which logs identified the application server could not mount it's storage.
- **Application configuration:** A unique application secret key needed to be generated separately, stored in a Kubernetes Secret and referenced in the application server's manifest. The application refused to start without it.
- **NFS permissions:** UID & GID was not initially set for the container via the manifest, leading to a permissions fault for the NFS share. Corrected and observed successful creation of directories by the container.

## 5. Lessons Learned

- Resource planning: Existing cluster capacity and workload placement should be reviewed before introducing new applications, particularly when storage and compute resources are relatively constrained.

- Manifest troubleshooting: Small configuration errors can prevent otherwise healthy components from working together. Checking pod events, application logs and the state of dependent resources helped identify and resolve the issues encountered.

## 6. Future Improvements

- Introduce a repeatable process for generating and managing application secrets, rather than relying on manual imperative creation
- Database PVC is being backed up via longhorn, however, a backup of the database itself is yet to be introduced.
- Resource limits may need further tuning.
- Introducing ArgoCD to the cluster would have massively reduced manual effort of recreating manifests on the cluster itself. 
