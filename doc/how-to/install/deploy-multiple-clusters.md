---
title: Deploy multiple clusters
sidebar_label: Deploy multiple clusters
sidebar_position: 5
description: Run more than one cluster in the same Kubernetes cluster by confining each operator to a namespace.
---

# Deploy multiple clusters

If you have deployed a CelerData cluster by YAML manifests, you can write a new CelerDataCluster CR YAML to deploy
another CelerData cluster.

If you deployed with the `operator` + `celerdata` charts, deploy another cluster with a
second `celerdata` release — one operator can manage many clusters.

If you deployed with `kube-celerdata`, a second release brings a second operator with it, so
you must confine each one to a namespace first. See
[Helm chart layout](../../explanation/helm-chart-layout.md).

## Deploy another CelerData cluster by `kube-celerdata` Helm chart

By default, the operator will watch all namespaces. If you want to deploy another CelerData cluster
by `kube-celerdata`, you should limit `each operator` to watch a specific namespace.

```yaml
operator:
  celerDataOperator:
    watchNamespace: "your-namespace"
```

> you can also add `--set operator.celerDataOperator.watchNamespace="your-namespace"` to the `helm` command which has
> higher priority.

So, the steps to deploy multiple CelerData clusters by `kube-celerdata` are:

1. update `values.yaml` file of the first deployed CelerData cluster to limit the operator to watch a specific
   namespace.
2. upgrade the first CelerData cluster.
3. install the second CelerData cluster by the same `kube-celerdata` chart, and do not forget to specify the namespace.
