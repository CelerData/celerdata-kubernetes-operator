---
title: Add the Helm chart repository
sidebar_label: Add the Helm repo
sidebar_position: 3
description: Register the PhoenixAI Helm chart repository so you can install the operator and cluster charts.
---

# Add the Helm chart repository

1. Add the Helm Chart Repo.

   ```bash
   helm repo add celerdata https://celerdata.github.io/phoenixai-kubernetes-operator
   ```

2. Update the Helm Chart Repo to the latest version.

   ```bash
   helm repo update celerdata
   ```

3. View the Helm Chart Repo that you added.

   ```bash
   $ helm search repo celerdata
   NAME                        CHART VERSION   APP VERSION   DESCRIPTION
   celerdata/kube-celerdata    1.11.6          4.1-latest    kube-celerdata includes two subcharts, operator a...
   celerdata/operator          1.11.6          1.11.6        A Helm chart for CelerData operator
   celerdata/celerdata         1.11.6          4.1-latest    A Helm chart for CelerData cluster
   celerdata/warehouse         1.11.6          4.1-latest    A Helm chart for CelerData warehouse
   ```

See [Deploy a cluster with Helm](./deploy-with-helm.md) for what to do next, and
[Helm charts](../../reference/helm-charts.md) for what each chart installs.
