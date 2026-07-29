---
title: Deploy a cluster with Helm
sidebar_label: Deploy with Helm
sidebar_position: 2
description: Install the operator and a cluster with the kube-celerdata umbrella chart, or with the operator and celerdata charts separately.
---

# Deploy a cluster with Helm

The quickest route is the `kube-celerdata` umbrella chart, which installs the operator and
a cluster together.

```bash
helm repo add celerdata https://celerdata.github.io/phoenixai-kubernetes-operator
helm repo update celerdata
helm install kube-celerdata celerdata/kube-celerdata -n celerdata --create-namespace
```

To review and edit the defaults before installing:

```bash
helm show values celerdata/kube-celerdata > values.yaml
helm install kube-celerdata celerdata/kube-celerdata -n celerdata --create-namespace -f values.yaml
```

For more flexibility — one operator managing several clusters — install the `operator` and
`celerdata` charts separately instead. See
[Helm chart layout](../../explanation/helm-chart-layout.md) for the trade-off and
[Helm charts](../../reference/helm-charts.md) for the full chart list.

## See also

- [Add the Helm chart repository](./add-helm-repo.md)
- [Deploy multiple clusters](./deploy-multiple-clusters.md)
- [Deploy a warehouse](./deploy-warehouse.md)
