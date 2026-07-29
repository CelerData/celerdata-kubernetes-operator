---
title: Configure logging
sidebar_label: Configure logging
sidebar_position: 5
description: Persist component logs on a volume, send them to the console, or ship them to Datadog.
---

# Configure logging

By default logs are written to an `emptyDir` and lost on pod restart
([why](../../explanation/logging.md)). This guide covers the three ways to change that.

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
