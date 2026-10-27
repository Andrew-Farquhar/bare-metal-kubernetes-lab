# Plex Deployment

## Overview

Plex Media Server was migrated from Docker on the NAS into the Kubernetes cluster. The aim was to bring Plex under Kubernetes management while retaining the existing server configuration and keeping media files on the NAS.

The migration also provided an opportunity to use the cluster's existing storage, networking and ingress infrastructure rather than introducing separate solutions specifically for Plex.

## Deployment

- **Namespace:** `apps`
- **Helm chart:** `plex/plex-media-server`
- **Chart version:** `1.9.0`
- **Application version:** `1.43.3.10896`
- **Configuration location:** `~/helm/plex/plex-values.yaml`

The Plex Helm repository was added and the chart's default values were reviewed before creating a custom values file specifying an existing PVC, limited resources (2 CPU, 250m), service and httpRoutes and Plex's UID/GID alongside a liveness, readiness and startup Probe.

## Networking

- **Ingress:** `HTTPRoute via Traefik`
- **Hostname:** `plex.home`
- **MetalLB IP:** `192.168.1.245`
- **Media Server port:** `32400`

Plex is accessible through the cluster's existing Traefik Gateway API configuration. The HTTPRoute directs requests for `plex.home` to the Plex Service.

A MetalLB IP address is also advertised for Plex to workaround some of the challenges that Plex's server discovery via the Plex API presents, most notably being unable to access the server through plex.home on Smart TV clients. This allowed for a LAN IP and Port to be specified in the client's configuration.

## Storage

### Configuration

- **StorageClass:** `Longhorn`
- **PersistentVolumeClaim:** `plex-pvc`
- **Requested capacity:** `25Gi`
- **Replica count:** `2`

The PVC was initially created with a smaller capacity at ~ 15Gi and then expanded after the configuration import ran out of space.

### Media

- **Storage location:** NAS 
- **Filesystem:** ZFS
- **Access method:** NFS
- **PersistentVolumeClaim:** `nas-media-pvc`
- **Container mount path:** `/media`

The media collection remains on the NAS rather than being copied into Longhorn. The NFS-backed volume exposes the existing media directory to Plex inside the pod.

This separates application state from media storage, avoiding the need to duplicate a large media collection across Longhorn replicas.

## Configuration

The main configuration decisions were:

- An existing PVC was used to preserve Plex's configuration.
- The NAS media directory was mounted into the container using a separate PVC.
- The container was configured with the appropriate user and group settings for access to the media.
- An HTTPRoute was configured to expose Plex through the existing Traefik Gateway.
- The timezone was set to `Europe/London`.

Some custom configuration was needed to navigate plex's podSecurityContext, allowing for the init container to run as root and execute the chart's config import script without allowing plex as a whole to run as root.

## Migration

The existing Docker configuration was archived and imported into the Longhorn-backed PVC using an init container (plex provide a handy script in the helm chart for this exact purpose).

The archive was temporarily served from the NAS using Nginx so that the init container could retrieve it over HTTP.

The original Docker Plex container was stopped before migration and remains stopped as a rollback option (deleted as of 27/10/2026).

## Validation

The following tests were performed to confirm the migration was successful:

- Existing server identity and libraries were preserved.
- Existing media remained accessible through the NFS-backed volume.
- Playback was tested from existing clients.
- Clients were able to connect to the Kubernetes instance.
- Plex remained accessible after the pod was deleted and recreated.
- The configuration remained present on the Longhorn PVC after recreation.

## Problems / Lessons Learned

### Automatic library scanning

After migration, Plex no longer appeared to detect new media automatically.

The media files remained visible through the NFS-backed PVC, but remote filesystem changes do not necessarily generate the notifications Plex uses to trigger automatic library scans.

Plex server has been configured to scan the media library at 15 minute intervals to negate this and manually triggered scans remain a valid option.

## Outcome

Plex is now running in Kubernetes, with application state stored on Longhorn and media retained on the NAS.

The migration preserved the existing Plex server configuration and libraries, and playback continued to work from existing clients. The previous Docker deployment remains stopped on the NAS in case rollback is required (deleted as of 27/10/2026).

