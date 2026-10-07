# Gateway API and Traefik

## Purpose

Introduced Gateway API and Traefik to provide ingress control into the Kubernetes cluster. Gateway API was chosen over Traefik-specific tooling so that application routing is defined using Kubernetes-standard resources such as `Gateway` and `HTTPRoute`.

Traefik is responsible for implementing those resources and handling the actual traffic.

## Prerequisites

* Helm

## Installation

### Gateway API

* Obtained the standard Gateway API CRDs from the Kubernetes Gateway API GitHub release.
* Applied the supplied YAML directly to the cluster.
* Verified the installation by running `kubectl get crd | grep gateway.networking.k8s.io` and confirming that the Gateway API CRDs were present.

### Helm

* Installed Helm using the installation method provided by the Helm project.
* Added the Traefik Helm repository.
* Updated the Helm repository information to make the Traefik chart available.

### Traefik

* Created a custom `values.yaml` rather than relying entirely on the chart defaults.
* Used custom values to configure the Gateway API provider and how Traefik is exposed.
* Installed Traefik using the Helm CLI:

```bash
helm install traefik traefik/traefik -n traefik -f traefik-values.yaml --wait
```

## Configuration

### Helm Values

```yaml
service:
  spec:
    type: NodePort

ingressRoute:
  dashboard:
    enabled: true
    matchRule: Host(`dashboard.localhost`)
    entryPoints:
      - web

providers:
  kubernetesGateway:
    enabled: true

gateway:
  listeners:
    web:
      namespacePolicy:
        from: All
```

* Configured the Traefik Service as a `NodePort` rather than the chart default of `LoadBalancer`. The current Kubernetes cluster does not have a LoadBalancer implementation to provide an external IP. Using NodePort allows the service to be exposed through the IP address and port of a Kubernetes node.
* The Kubernetes Gateway provider was enabled so that Traefik could interpret configurations defined using the Kubernetes Gateway API and use them to configure its routing.
* The Gateway listener was configured with `namespacePolicy` set to `All` to allow HTTPRoutes from other namespaces to attach to the Gateway.

## How Gateway API Works in This Cluster

Gateway API uses several resources to define how traffic is handled within the cluster.

### GatewayClass

The GatewayClass identifies the controller responsible for implementing Gateways that reference that class. In this cluster, the `traefik` GatewayClass identifies the Traefik Gateway controller.

### Gateway

The Gateway defines the network entry point managed by the Gateway controller. The `traefik-gateway` resource provides an HTTP listener through which traffic can enter Traefik.

The Gateway is located in the `traefik` namespace and uses the `traefik` GatewayClass.

### HTTPRoute

The HTTPRoute defines how HTTP traffic entering through the Gateway should be routed to an application.

The nginx HTTPRoute is located in the `default` namespace and routes requests for `nginx.home` to the `nginx` Kubernetes Service on port 80.

The Gateway listener was configured to allow HTTPRoutes from other namespaces, allowing the HTTPRoute in `default` to attach to the Gateway in `traefik`.

## Traffic Flow

Conceptually, traffic to the nginx application follows this routing path:

```text
Client
   |
   v
Node IP:NodePort
   |
   v
Traefik
   |
   v
Gateway API configuration
   |
   v
HTTPRoute
   |
   v
nginx Service
   |
   v
nginx Pod
```

A request is first sent to the NodePort exposed by the Traefik Service. Traefik receives the request and uses the Gateway API configuration to determine which HTTPRoute matches it. The HTTPRoute then directs the request to the nginx Service, which forwards it to one of the nginx Pods.

## Hostname-Based Routing

The HTTPRoute uses hostname-based routing to determine which requests it should handle.

The nginx route is configured for the hostname `nginx.home`. A request containing this hostname is matched by the HTTPRoute and forwarded to the nginx Service.

This allows multiple applications to use the same Traefik entry point while being separated by hostname rather than requiring a different port for each application.

## Validation

The Gateway API CRDs were verified after installation using:

```bash
kubectl get crd | grep gateway.networking.k8s.io
```

The Traefik GatewayClass and Gateway were then verified using:

```bash
kubectl get gatewayclass,gateway -A
```

The GatewayClass was shown as accepted and the Gateway as programmed.

The HTTPRoute was inspected using:

```bash
kubectl describe httproute nginx -n default
```

The HTTPRoute reported both `Accepted=True` and `ResolvedRefs=True`, confirming that it had successfully attached to the Gateway and resolved the nginx Service.

End-to-end routing was tested by sending HTTP requests to the Traefik NodePort. Hostname-based routing was also tested using the `nginx.home` hostname, with the request successfully reaching the nginx application.

## Problems / Lessons Learned

The initial Traefik installation used the wrong Helm values path for configuring the Service type. `service.type` was set to `NodePort`, but the Traefik chart expects the Service type under `service.spec.type`.

This resulted in Traefik being deployed with a `LoadBalancer` Service that remained in a pending state because the cluster did not have a LoadBalancer implementation providing an external address.

The chart values were corrected to:

```yaml
service:
  spec:
    type: NodePort
```

Traefik was then successfully installed with a NodePort Service.

This reinforced the importance of checking the Helm chart's actual values structure rather than assuming configuration keys based on their apparent names.

## Current State

Gateway API and Traefik are operational in the cluster.

Traefik is exposed using a NodePort and is configured to use the Kubernetes Gateway API provider. A GatewayClass, Gateway and HTTPRoute are successfully working together to route traffic to an nginx application.

Hostname-based routing using `nginx.home` has also been successfully demonstrated.

## Future Work

* Configure DNS so application hostnames resolve without manually specifying the Host header.
* Add HTTPS and TLS termination.
* Add additional applications using HTTPRoutes.
* Integrate Tailscale for external/private access.
* Consider a LoadBalancer implementation such as MetalLB if required.
