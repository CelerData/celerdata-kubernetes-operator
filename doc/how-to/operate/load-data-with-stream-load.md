---
title: Load data with Stream Load
sidebar_label: Load data with Stream Load
sidebar_position: 3
description: Deploy the FE Proxy so external clients can load data into the cluster with Stream Load.
---

# Load data with Stream Load

To load data from outside the cluster network you need the FE Proxy, which rewrites the
HTTP 307 redirect that FE returns. See
[Stream Load and the FE Proxy](../../explanation/stream-load-and-fe-proxy.md) for why, and
for the non-HTTP cases it cannot handle.

Send traffic to the FE Proxy HTTP port (8080) instead of the FE HTTP port (8030).

## Deploy Fe Proxy Using Helm

If you install CelerData with Helm, you can add the following configuration to the `values.yaml` file:

For `kube-celerdata` Helm chart:

```yaml
celerdata:
  celerDataFeProxySpec:
    enabled: true
    replicas: 1
    # set the resolver for nginx server, default kube-dns.kube-system.svc.cluster.local
    resolver: ""
    limits:
      cpu: 1
      memory: 2Gi
    requests:
      cpu: 1
      memory: 2Gi
    service:
      type: NodePort
      ports:
        - name: http-port   # fill the name from the fe proxy service ports
          containerPort: 8080
          nodePort: 30180
          port: 8080
```

For `celerdata` Helm chart:

```yaml
celerDataFeProxySpec:
  enabled: true
  replicas: 1
  # set the resolver for nginx server, default kube-dns.kube-system.svc.cluster.local
  resolver: ""
  limits:
    cpu: 1
    memory: 2Gi
  requests:
    cpu: 1
    memory: 2Gi
  service:
    type: NodePort
    ports:
      - name: http-port   # fill the name from the fe proxy service ports
        containerPort: 8080
        nodePort: 30180
        port: 8080
```

Please
see https://github.com/celerdata/phoenixai-kubernetes-operator/blob/main/helm-charts/charts/kube-celerdata/values.yaml
for more details about how to configure `celerDataFeProxySpec`.

## Deploy Fe Proxy Using CelerDataCluster CR

If you install CelerData with CelerDataCluster CR yaml, please see
[deploy_a_celerdata_cluster_with_fe_proxy.md](../../../examples/celerdata/deploy_a_celerdata_cluster_with_fe_proxy.yaml)
