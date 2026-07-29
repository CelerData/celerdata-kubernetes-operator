---
title: Configure logging
sidebar_label: Configure logging
sidebar_position: 5
description: Persist component logs on a volume, send them to the console, or ship them to Datadog.
---

# Configure logging

By default, component logs go to an `emptyDir` volume, which means **a pod restart takes the
logs with it** — exactly when you most want to read them. This guide covers the three ways
to change that: persist logs on a volume, send them to the container console, or ship them
to Datadog.

Pick one and follow it; [how the three compare, and why the default behaves this
way](#how-these-three-compare) is at the end.

## 3. Persisting Logs

All component Spec definitions have a `storageVolumes` field, allowing users to customize the storage volume. Taking FE
as an example:

```yaml
spec:
  celerDataFeSpec:
    storageVolumes:
      - mountPath: /opt/starrocks/fe/log
        name: fe-log
        storageSize: 10Gi
        # storageClassName: ""  # If storageClassName is not set, Kubernetes will use the default storage class.
```

If `storageClassName` is left blank, the default storage class will be used. You can view available storage classes in
the Kubernetes cluster with `kubectl get storageclass`. **Note: selecting an appropriate storage class is crucial as it
dictates the type of storage volume**. See https://kubernetes.io/docs/concepts/storage/persistent-volumes/ for more
information.

> Attention: The Operator will create PVC resources for the CelerData cluster. The storage class controller will then
> automatically generate the specific storage volume.

### 3.1 Helm Chart Supports Persisting Logs

If you deployed the CelerData cluster using Helm Chart, you can modify the `values.yaml` content to persist logs. Here's
an example for the FE component:

For the kube-celerdata Helm Chart, you can configure as:

```yaml
celerdata:
  celerDataFeSpec:
    storageSpec:
      name: "fe"
      storageSize: 10Gi
      logStorageSize: 10Gi
      # storageClassName: ""  # If storageClassName is not set, Kubernetes will use the default storage class.
```

For the celerdata Helm Chart, configure as:

```yaml
celerDataFeSpec:
  storageSpec:
    name: "fe"
    storageSize: 10Gi
    logStorageSize: 10Gi
    # storageClassName: ""  # If storageClassName is not set, Kubernetes will use the default storage class.
```

> Note:
>
> 1. In FE, `storageSize` specifies the size of the storage volume for metadata, while `logStorageSize` designates the
     size of the storage volume for logs.
> 2. Fe container stop running if the storage volume free space which the fe meta residents, is less than 5Gi. Set it to
     at least 10GB or more.

## 4. Logging to the Console

By setting the environment variable `LOG_CONSOLE = 1`, you can direct component logs to the console. Here's an example
for FE:

```yaml
spec:
  celerDataFeSpec:
    feEnvVars:
      - name: LOG_CONSOLE
        value: "1"
```

### 4.1 Helm Chart Supports Environment Variable Settings

If you've deployed the CelerData cluster using Helm Chart, you can modify the `values.yaml` content to set environment
variables. An example for the FE component:

For the kube-celerdata Helm Chart, configure as:

```yaml
celerdata:
  celerDataFeSpec:
    feEnvVars:
      - name: LOG_CONSOLE
        value: "1"
```

For the celerdata Helm Chart, configure as:

```yaml
celerDataFeSpec:
  feEnvVars:
    - name: LOG_CONSOLE
      value: "1"
```

## 5. Collecting Logs into Datadog

Refer to: [Datadog](../integration/integrate-datadog.md).

## How these three compare

Now that you have configured one, here is the trade-off you picked.

The default is `emptyDir`: a directory created when the pod starts and destroyed when it
stops. It costs nothing and needs no storage class, which is why it is the default, but its
lifetime is the pod's lifetime. When a container crashes and restarts, the logs describing
the crash are already gone.

**Persisting logs** on a PersistentVolume decouples the logs from the pod. The operator
creates a PVC per volume, so the logs survive restarts, rescheduling, and node failure. The
cost is a volume per component — and for FE, note that `storageSize` covers metadata while
`logStorageSize` covers logs. Keep FE metadata at 10 GB or more: the FE container stops if
free space on the metadata volume falls below 5 GB, which turns a full log volume into an
outage if you share them.

**Logging to the console** with `LOG_CONSOLE=1` writes to stdout instead of files, which
puts the logs where every Kubernetes tool already looks — `kubectl logs`, and `kubectl logs
-p` for the generation before a restart. That `-p` is the entire benefit over the default.
It is one generation back, retained by the container runtime and rotated on its schedule,
not yours. Good for interactive debugging, not for an audit trail.

**Shipping to Datadog** is the option that survives the cluster rather than just the pod,
and it is the only one that gives you search and alerting across components. It also means
your logs leave the cluster, with whatever that implies for retention cost and data
handling.

These are not exclusive. Console plus a collector is a common pairing: the collector does
the durable copy, and `kubectl logs` stays useful for a quick look.

For where each component writes its files, see
[Log file locations](../../reference/log-file-locations.md).
