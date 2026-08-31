---
sidebar_position: 3
---

# Deploy PhoenixAI With Helm

We have split the kube-anywhere chart into two subcharts: operator and PhoenixAI since v1.8.0.

Installing kube-anywhere is equivalent to installing both operator and `phoenixai` subcharts (and, if you
set `anywhere.enabled=true`, the optional `anywhere` subchart — the PhoenixAI Anywhere console), and
uninstalling kube-anywhere is equivalent to uninstalling the subcharts it installed.

If you want more flexibility in managing your PhoenixAI clusters, you can install operator and `phoenixai` subcharts
separately.

These are the charts in this repository:

```bash
$ helm repo add phoenixai https://celerdata.github.io/phoenixai-kubernetes-operator
$ helm repo update phoenixai
$ helm search repo phoenixai
NAME                       CHART VERSION    APP VERSION  DESCRIPTION
# install operator and phoenixai (optionally anywhere)
phoenixai/kube-anywhere    2.0.0            4.1-latest   kube-anywhere includes three subcharts, operato...
# install operator only
phoenixai/operator         2.0.0            2.0.0        A Helm chart for PhoenixAI operator
# install phoenixai only
phoenixai/phoenixai        2.0.0            4.1-latest   A Helm chart for PhoenixAI cluster
# install the PhoenixAI Anywhere console only
phoenixai/anywhere         2.0.0            v2.0.0       A Helm chart for PhoenixAI Anywhere — a read-on...
# install a warehouse for an existing PhoenixAI cluster
phoenixai/warehouse        2.0.0            4.1-latest   Warehouse is currently a feature of the Phoenix...
```

1. `kube-anywhere` includes three subcharts, `operator`, `phoenixai`, and the optional `anywhere`.
   See [kube-anywhere](../../helm-charts/charts/kube-anywhere/README.md) for more details.
2. `operator` is the Helm chart for PhoenixAI operator.
   See [operator](../../helm-charts/charts/kube-anywhere/charts/operator/README.md) for more details.
3. `phoenixai` is the Helm chart for PhoenixAI cluster.
   See [phoenixai](../../helm-charts/charts/kube-anywhere/charts/phoenixai/README.md) for more details.
4. `anywhere` is the Helm chart for the PhoenixAI Anywhere console on its own — use it next to an
   operator you install and manage separately; through `kube-anywhere` the same chart is installed
   with `anywhere.enabled=true` and its values carry the `anywhere.` prefix.
   See [anywhere](../../helm-charts/charts/kube-anywhere/charts/anywhere/README.md) for more details.
