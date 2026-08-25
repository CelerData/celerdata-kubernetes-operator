---
title: Quick start with Amazon S3
sidebar_label: Quick start — Amazon S3
sidebar_position: 1
description: Install a shared-data PhoenixAI cluster, a warehouse, and the Anywhere console, with Amazon S3 as the cluster's storage.
---

# Quick Start With Amazon S3

This builds a complete environment on a single Kubernetes cluster: a shared-data PhoenixAI cluster
with three coordinators and one compute node, a warehouse, Prometheus, and the PhoenixAI Anywhere
console — using an Amazon S3 bucket for the cluster's data and the console's own artifacts.

It is written for a local cluster (kind) so you can try it on a laptop, but nothing here is
kind-specific except the `storageClassName` and the resource sizes.

For self-hosted or air-gapped object storage, see
[Quick start — MinIO](./quickstart_minio.md), which differs only in how storage is configured.

{/* COMMON-BEGIN: prerequisites */}

## Before you start

| You need | Notes |
| --- | --- |
| `kubectl`, `helm` | Any recent version |
| A Kubernetes cluster | `kind create cluster` is enough. Measured on this environment: **3.9 GB** of memory and under one CPU core at rest, with 3 coordinators, 2 compute nodes and MinIO running. 8 GB available to Docker leaves comfortable headroom; the chart values cap each coordinator and compute node at 2 GiB, so a cluster under query load can use more |
| Enterprise PhoenixAI images | The FE and CN images must be the enterprise (`-ee`) builds. With community images the cluster starts but **no warehouse compute pods are ever created, and nothing reports an error** |
| A MySQL client | To check the cluster and to run SQL |

Add the chart repository and see what it offers:

```bash
helm repo add phoenixai https://celerdata.github.io/phoenixai-kubernetes-operator
helm repo update phoenixai
helm search repo phoenixai
```

Use the chart names and versions that command lists. One chart — `kube-anywhere` — installs the
operator, a PhoenixAI cluster, and (with `anywhere.enabled=true`) the Anywhere console. It is also
distributed as a release archive, so if you do not see it in the repository, install it from the
`.tgz` for your release.

{/* COMMON-END: prerequisites */}

{/* DELTA-BEGIN: object storage prerequisites */}

## The bucket

Create (or choose) an S3 bucket, and have ready:

- the bucket name and its region;
- an access key and secret key that can **read and write** the bucket. The cluster writes all of
  its data there, and the console verifies its own prefix with a write, read and delete at startup.

One bucket serves both the cluster and the console, kept apart by key prefix — this guide uses
`data/` for the cluster and `anywhere/` for the console. Nothing else in the bucket is touched.

{/* DELTA-END: object storage prerequisites */}

{/* COMMON-BEGIN: namespace and prometheus */}

## Create the namespace and install Prometheus

```bash
kubectl create namespace phoenixai
```

Prometheus is optional, but without it the console's monitoring pages have no data. The
`kube-prometheus-stack` chart also scrapes kubelet/cAdvisor and kube-state-metrics by default,
which is what makes per-pod CPU and memory utilization appear.

Install it **before** the cluster. The cluster and warehouse charts render ServiceMonitors, and
those need the Prometheus operator's CRDs to already exist — install them the other way round and
the ServiceMonitors are skipped, with no error, leaving the monitoring pages empty for a reason
nothing on screen explains.

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update prometheus-community
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace
```

:::caution The ServiceMonitors must carry the label your Prometheus selects on
`kube-prometheus-stack` defaults `serviceMonitorSelector` to
`matchLabels: {release: <helm release name>}`. The cluster and warehouse charts do
not add that label, so with the install above and nothing else, **Prometheus
scrapes none of the PhoenixAI targets** — it collects only its own stack, and the
console's monitoring pages stay empty with nothing on screen to say why.

Add it through `metrics.serviceMonitor.labels` in the values below. If you
installed the stack under a different release name, use that name.
:::

{/* COMMON-END: namespace and prometheus */}

## Install the operator, the cluster and the console

One `helm install` of the `kube-anywhere` chart deploys all three. Write `cluster-values.yaml`.
Replace the image repositories with your registry, and the bucket, region, endpoint and keys with
your own.

```yaml
operator:
  phoenixAIOperator:
    # Anywhere reads everything through the operator's gRPC API. Without this
    # the console installs but shows no clusters.
    enableApiServer: true
    # One operator per namespace: an unscoped operator watches every namespace
    # and competes with any other operator in the cluster.
    watchNamespace: "phoenixai"

phoenixai:
  # Renders FE and CN ServiceMonitors, which the console's monitoring pages expect.
  metrics:
    serviceMonitor:
      enabled: true
      labels:
        release: prometheus
  phoenixAICluster:
    name: kube-anywhere
    # Shared-data is FE + CN.
    enabledCn: true
    waitForFullRollout: true

  phoenixAIFeSpec:
    replicas: 3
    image:
      repository: <your-registry>/fe-ubuntu
      tag: 4.1.4-ee
    config: |
      LOG_DIR = ${STARROCKS_HOME}/log
      JAVA_OPTS="-Dlog4j2.formatMsgNoLookups=true -Xmx1024m -XX:+UseG1GC"
      http_port = 8030
      rpc_port = 9020
      query_port = 9030
      edit_log_port = 9010
      run_mode = shared_data
      cloud_native_meta_port = 6090
      cloud_native_storage_type = S3
      # DELTA vs MinIO: the storage volume is built from these settings.
      enable_load_volume_from_conf = true
      aws_s3_path = <bucket>/data
      aws_s3_region = <region>
      aws_s3_endpoint = s3.<region>.amazonaws.com
      aws_s3_access_key = <access-key>
      aws_s3_secret_key = <secret-key>
      aws_s3_use_aws_sdk_default_behavior = false
    resources:
      limits: { cpu: 2, memory: 2Gi }
      requests: { cpu: 10m, memory: 10Mi }
    storageSpec:
      name: fe-storage
      # Set this explicitly. An empty value renders as YAML null and the CRD rejects it.
      storageClassName: standard
      storageSize: 10Gi
      logStorageSize: 1Gi

  phoenixAICnSpec:
    replicas: 1
    image:
      repository: <your-registry>/cn-ubuntu
      tag: 4.1.4-ee
    config: |
      sys_log_level = INFO
      thrift_port = 9060
      webserver_port = 8040
      heartbeat_service_port = 9050
      brpc_port = 8060
      datacache_enable = true
      datacache_mem_size = 5%
      # Must be greater than zero in shared-data mode, or CREATE TABLE fails
      # with "no valid cache space".
      datacache_disk_size = 4294967296
    resources:
      limits: { cpu: 4, memory: 2Gi }
      requests: { cpu: 10m, memory: 10Mi }
    storageSpec:
      name: cn-storage
      storageClassName: standard
      storageSize: 10Gi
      logStorageSize: 1Gi

anywhere:
  # The console is opt-in because it needs object storage of its own.
  enabled: true
  image:
    repository: <your-registry>/anywhere
    tag: <version>

  # The operator's gRPC API Service, in this namespace.
  operatorApiAddrs:
    - "kube-anywhere-api:9090"
  watchNamespaces:
    - "phoenixai"

  dependencies:
    # DELTA vs MinIO: same bucket as the cluster, different prefix, and no
    # path-style addressing for Amazon S3.
    s3:
      bucket: "<bucket>"
      path: "anywhere"
      region: "<region>"
      endpoint: "https://s3.<region>.amazonaws.com"
      accessKey: "<access-key>"
      secretKey: "<secret-key>"
      usePathStyle: false
    prometheus:
      enabled: true
      endpoint: http://prometheus-kube-prometheus-prometheus.monitoring:9090
```

```bash
helm install phoenixai phoenixai/kube-anywhere \
  --namespace phoenixai -f cluster-values.yaml
kubectl -n phoenixai get pods -w
```

{/* COMMON-BEGIN: fe logging note */}

:::note Keep FE logs as files
Do not set `LOG_CONSOLE=1` on the FE. The console's audit-log search and the support bundle's log
collection both read log **files** from the log volume; console-only logging leaves both empty.
:::

{/* COMMON-END: fe logging note */}

{/* COMMON-BEGIN: verify cluster sql */}

When the pods are running, check the cluster over SQL:

```bash
kubectl -n phoenixai exec -it kube-anywhere-fe-0 -- \
  mysql -h127.0.0.1 -P9030 -uroot -e "SHOW BACKENDS\G SHOW WAREHOUSES\G"
```

{/* COMMON-END: verify cluster sql */}

{/* COMMON-BEGIN: warehouse */}

## Install a warehouse

A warehouse is a compute group of its own, deployed by its own chart. The release name **is** the
warehouse name, and it must go in the same namespace as the cluster.

```yaml
# warehouse-values.yaml
metrics:
  serviceMonitor:
    enabled: true
    labels:
      release: prometheus
spec:
  phoenixAIClusterName: "kube-anywhere"
  replicas: 1
  image:
    repository: <your-registry>/cn-ubuntu
    tag: 4.1.4-ee
  config: |
    sys_log_level = INFO
    thrift_port = 9060
    webserver_port = 8040
    heartbeat_service_port = 9050
    brpc_port = 8060
    datacache_enable = true
    datacache_mem_size = 5%
    datacache_disk_size = 4294967296
  resources:
    limits: { cpu: 2, memory: 2Gi }
    requests: { cpu: 10m, memory: 10Mi }
  storageSpec:
    name: warehouse-cn-storage
    storageClassName: standard
    storageSize: 10Gi
    logStorageSize: 1Gi
```

```bash
helm install wh1 phoenixai/warehouse --namespace phoenixai -f warehouse-values.yaml
kubectl -n phoenixai rollout restart deployment kube-anywhere-operator
```

:::caution The operator must be restarted after the first warehouse
The `PhoenixAIWarehouse` CRD ships in the warehouse chart, and the operator checks whether that CRD
exists **once, at startup**. Install the operator first — as you just did — and it has no warehouse
controller registered, so the `PhoenixAIWarehouse` object you create is never reconciled.

Nothing reports this. `kubectl get paw` shows the object with an empty `STATUS`, there are no pods,
no events, and no warehouse line in the operator log. The restart above is what makes the controller
appear; after it, `kubectl -n phoenixai logs deployment/kube-anywhere-operator` includes:

```text
Starting Controller {"controllerKind": "PhoenixAIWarehouse"}
```

Only the first warehouse needs this. Once the CRD exists, later warehouse releases are reconciled
immediately.
:::

Confirm it exists as a warehouse rather than merely as pods — `SHOW WAREHOUSES` is the check that
matters:

```bash
kubectl -n phoenixai exec -it kube-anywhere-fe-0 -- \
  mysql -h127.0.0.1 -P9030 -uroot -e "SHOW WAREHOUSES\G"
```

{/* COMMON-END: warehouse */}

{/* COMMON-BEGIN: sign in */}

## Sign in

The console was installed together with the cluster (the `anywhere:` block above). Wait for it:

```bash
kubectl -n phoenixai rollout status statefulset/anywhere
kubectl -n phoenixai port-forward svc/anywhere 8090:8090
```

Check the service answers, then open the console at `http://localhost:8090`:

```bash
curl -s localhost:8090/api/v1/health
# {"code":20000,"data":{"status":"ok"}}
```

Admin accounts live in the `anywhere-admin` Secret — one key per username. If you did not
supply any, a single `admin` account was generated with a random password:

```bash
kubectl -n phoenixai get secret anywhere-admin \
  -o jsonpath='{.data.admin}' | base64 -d; echo
```

Add, remove or rotate accounts by editing that Secret; changes take effect within about a minute
and need no restart.

To reach the **Cluster Console** — the per-cluster view, with the data catalog, query insights and
system monitoring — go to `http://localhost:8090/cluster-console/login` and sign in with a database
user from the cluster itself. That is a PhoenixAI database user, created in the cluster with SQL,
not an Anywhere account.

{/* COMMON-END: sign in */}

{/* COMMON-BEGIN: what to enable next */}

## What to enable next

**Query insights is off by default.** The page needs two settings, in two different places:

1. `anywhere.queryHistory.enabled` in the chart values;
2. the FE configuration `enable_collect_query_detail_info` on every FE, either in `fe.conf` or with
   `ADMIN SET FRONTEND CONFIG`.

The page names both in its empty state, so you do not have to remember which is missing.

{/* COMMON-END: what to enable next */}

{/* COMMON-BEGIN: troubleshooting shared */}

## Troubleshooting

**`CREATE TABLE` fails with "no valid cache space".** `datacache_disk_size` is zero on the compute
nodes. It must be greater than zero in shared-data mode.

**The CRD rejects the cluster with a `storageClassName` type error.** An empty `storageClassName`
renders as YAML null. Set it to a real class (`kubectl get storageclass`).

**`CREATE TABLE` times out with "unfinished replicas".** A compute node that started moments ago
can exceed the FE's `tablet_create_timeout_second` (10 seconds by default). Retry, or raise it with
`ADMIN SET FRONTEND CONFIG ("tablet_create_timeout_second" = "20")`.

**The console shows no clusters.** The operator was installed without
`phoenixAIOperator.enableApiServer=true`, so there is no gRPC API for Anywhere to read.

**A warehouse never gets compute pods, with no error anywhere.** Two causes, in the order worth
checking. First, the operator has not been restarted since the warehouse chart installed the
`PhoenixAIWarehouse` CRD, so it holds no warehouse controller — `kubectl -n phoenixai logs
deployment/kube-anywhere-operator | grep PhoenixAIWarehouse` returns nothing, and
`kubectl rollout restart deployment kube-anywhere-operator` fixes it. Second, the images are
community builds rather than enterprise `-ee`.

**Monitoring pages are empty.** Prometheus is not installed, `anywhere.dependencies.prometheus` is not set,
or the ServiceMonitors were not rendered (`metrics.serviceMonitor.enabled`). The console has a
dependency check for this under the admin API.

{/* COMMON-END: troubleshooting shared */}
