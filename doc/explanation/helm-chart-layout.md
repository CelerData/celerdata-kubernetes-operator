---
title: Helm chart layout
sidebar_label: Helm chart layout
sidebar_position: 2
description: Why there are three charts instead of one, what each installs, and why watchNamespace matters for multiple clusters.
---

# Helm chart layout

We have split the kube-celerdata chart into two subcharts: operator and CelerData since v1.8.0.

Installing kube-celerdata is equivalent to installing both operator and `celerdata` subcharts, and uninstalling
kube-celerdata is equivalent to uninstalling both operator and `celerdata` subcharts.

If you want more flexibility in managing your CelerData clusters, you can install operator and `celerdata` subcharts
separately.

## Consequences for multiple clusters

By default the operator watches every namespace. One operator can manage many clusters, so
if you install `kube-celerdata` a second time you end up with two operators both
reconciling the same resources. Confining each operator with `watchNamespace` is what makes
a second `kube-celerdata` install safe.

See [Deploy multiple clusters](../how-to/install/deploy-multiple-clusters.md) for the
procedure, and [Helm charts](../reference/helm-charts.md) for what each chart contains.
