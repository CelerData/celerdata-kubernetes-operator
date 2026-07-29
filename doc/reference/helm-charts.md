---
title: Helm charts
sidebar_label: Helm charts
sidebar_position: 2
description: The charts published by this repository, what each one installs, and where its values.yaml lives.
---

# Helm charts

Four charts are published to `https://celerdata.github.io/phoenixai-kubernetes-operator`:

| Chart | Installs | Values |
| --- | --- | --- |
| `celerdata/kube-celerdata` | Umbrella chart: the `operator` and `celerdata` subcharts together | [values.yaml](../../helm-charts/charts/kube-celerdata/values.yaml) |
| `celerdata/operator` | The operator only | [values.yaml](../../helm-charts/charts/kube-celerdata/charts/operator/values.yaml) |
| `celerdata/celerdata` | A `CelerDataCluster` resource only | [values.yaml](../../helm-charts/charts/kube-celerdata/charts/celerdata/values.yaml) |
| `celerdata/warehouse` | A `CelerDataWarehouse` resource (Enterprise) | [values.yaml](../../helm-charts/charts/warehouse/values.yaml) |

Installing `kube-celerdata` is equivalent to installing `operator` and `celerdata`
together; uninstalling it removes both. Install them separately when you want one operator
to manage several clusters — see [Helm chart layout](../explanation/helm-chart-layout.md).

## Listing the charts

```bash
helm repo add celerdata https://celerdata.github.io/phoenixai-kubernetes-operator
helm repo update celerdata
helm search repo celerdata
```

Per-chart installation notes live with each chart:

- [kube-celerdata](../../helm-charts/charts/kube-celerdata/README.md)
- [operator](../../helm-charts/charts/kube-celerdata/charts/operator/README.md)
- [celerdata](../../helm-charts/charts/kube-celerdata/charts/celerdata/README.md)
- [warehouse](../../helm-charts/charts/warehouse/README.md)
