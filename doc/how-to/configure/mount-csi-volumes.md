---
title: Mount a CSI ephemeral volume
sidebar_label: Mount a CSI ephemeral volume
sidebar_position: 3
description: Mount a CSI ephemeral inline volume, such as the SPIFFE workload API socket, into component pods.
---

# Mount a CSI ephemeral volume

Some Kubernetes drivers publish a resource to a pod through a **CSI ephemeral inline volume**
rather than through a PersistentVolumeClaim. The SPIFFE CSI driver is the common example: it
mounts the SPIRE Agent's Workload API socket into the pod so the workload can obtain its
identity document (SVID).

The operator accepts a `csi` volume source alongside `emptyDir` and `hostPath`. Both
approaches below produce the same result — pick the one matching how you deploy. [Why a PVC
cannot carry this kind of volume](#why-not-a-persistentvolumeclaim) is explained at the end.

> **Prerequisite:** the CSI driver must already be installed in the cluster. The operator only
> references it by name; it does not install anything.

## By using CelerDataCluster CR yaml

Set `csi` on an entry of `storageVolumes`. The `csi` field takes a Kubernetes
[CSIVolumeSource](https://kubernetes.io/docs/reference/kubernetes-api/config-and-storage-resources/volume/#csi).

```yaml
apiVersion: celerdata.com/v1
kind: CelerDataCluster
metadata:
  name: celerdatacluster-sample
spec:
  celerDataFeSpec:
    replicas: 3
    image: starrocks/fe-ubuntu:latest
    storageVolumes:
      - name: spiffe-workload-api
        storageClassName: csi
        mountPath: /spiffe-workload-api
        readOnly: true
        csi:
          driver: csi.spiffe.io
          readOnly: true
```

`storageClassName: csi` may be omitted — setting the `csi` field alone is enough. Spelling it out
makes the intent obvious next to neighbouring PVC-backed volumes.

Supported on `celerDataFeSpec`, `celerDataBeSpec`, `celerDataCnSpec`, and `celerDataFeProxySpec`.

The operator rejects configurations that would otherwise be silently ignored:

| Configuration | Error |
| --- | --- |
| `storageClassName: csi` without a `csi` block, or with an empty `csi.driver` | `csi is required if storageClassName is csi, and csi.driver must not be empty` |
| `csi` together with `hostPath` on the same volume | `csi and hostPath can not be set at the same time` |
| `csi` together with any other `storageClassName` (`gp3`, `emptyDir`, ...) | `if csi is set, storageClassName must be empty or "csi"` |

## By using Helm Chart

Each component has a `csiVolumes` list, next to `emptyDirs` and `hostPaths`:

```yaml
celerDataFeSpec:
  csiVolumes:
    - name: spiffe-workload-api
      mountPath: /spiffe-workload-api
      readOnly: true
      csi:
        driver: csi.spiffe.io
        readOnly: true
```

When using the parent `kube-celerdata` chart, nest this under the `celerdata:` key.

## Example: mounting the SPIFFE workload API socket

Install the SPIFFE CSI driver first, following the
[SPIRE documentation](https://github.com/spiffe/spiffe-csi). Confirm it registered:

```bash
kubectl get csidriver csi.spiffe.io
```

Then deploy the cluster:

```bash
helm install celerdata celerdata/kube-celerdata -f values.yaml
```

with `values.yaml`:

```yaml
celerdata:
  celerDataFeSpec:
    csiVolumes:
      - name: spiffe-workload-api
        mountPath: /spiffe-workload-api
        readOnly: true
        csi:
          driver: csi.spiffe.io
          readOnly: true
```

Verify the socket reached the pod:

```bash
kubectl exec celerdatacluster-sample-fe-0 -- ls -l /spiffe-workload-api
```

Expected: a `spire-agent.sock` entry.

## Why not a PersistentVolumeClaim

A PVC cannot carry this kind of volume, which is why the `csi` field exists as a separate
volume source rather than as another `storageClassName`:

- Dynamic provisioning goes through the CSI Controller Service (`CreateVolume`). Drivers like
  `csi.spiffe.io` implement only the Node Service and declare `volumeLifecycleModes: [Ephemeral]`,
  so a PVC against them stays `Pending` forever.
- A bound PersistentVolume carries node affinity, which would stop the pod from ever being
  rescheduled to another node. The socket, however, is node-local and exists on every node.
- A PVC is meant to outlive its pod. This kind of volume must disappear with the pod.

For volumes that *should* outlive the pod, see [Mount a persistent
volume](./mount-persistent-volume.md).
