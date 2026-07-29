---
title: Mount a persistent volume
sidebar_label: Mount a persistent volume
sidebar_position: 1
description: Give FE metadata and BE data durable storage with storageVolumes in the CRD or storageSpec in Helm.
---

# Mount a persistent volume

CelerData Kubernetes Operator supports mounting persistent volumes to CelerData FE and BE pods. If not specified, the
operator will use emptyDir mode to store FE meta and BE data. **When container restarts, the data will be lost.**

This document describes how to mount persistent volumes to CelerData FE and BE pods. There are two ways to mount
persistent volumes to CelerData FE and BE pods:

1. Mounting persistent volumes to CelerData FE and BE pods by the CelerData CRD YAML file.
2. Mounting persistent volumes to CelerData FE and BE pods by Helm chart.

> Note: celerdata operator will create a new PVC for each storageVolume. You should not create PVC manually.

## 1. Mounting Persistent Volumes by CelerData CRD YAML File

If you want to use external storage to store FE meta and BE data for persistence, you can specify `storageVolumes` in
the corresponding component spec.

The following is an example of mounting persistent volumes to CelerData FE and BE.

```bash
apiVersion: celerdata.com/v1
kind: CelerDataCluster
metadata:
  name: kube-celerdata
  namespace: celerdata
  labels:
    cluster: kube-celerdata
spec:
  celerDataFeSpec:
    image: "us-west1-docker.pkg.dev/phrasal-verve-350013/celerdata/fe-ubuntu:4.1-latest"
    replicas: 1
    storageVolumes:
    - name: fe-meta
      storageClassName: standard-rwo  # standard-rwo is the default storageClassName in GKE.
      # fe container stop running if the disk free space which the fe meta directory residents, is less than 5Gi.
      storageSize: 10Gi
      mountPath: /opt/starrocks/fe/meta
    - name: fe-log
      storageClassName: standard-rwo
      storageSize: 5Gi
      mountPath: /opt/starrocks/fe/log
  celerDataBeSpec:
    image: "us-west1-docker.pkg.dev/phrasal-verve-350013/celerdata/be-ubuntu:4.1-latest"
    replicas: 3
    storageVolumes:
    - name: be-data
      storageClassName: standard-rwo
      storageSize: 1Ti
      mountPath: /opt/starrocks/be/storage
    - name: be-log
      storageClassName: standard-rwo
      storageSize: 1Gi
      mountPath: /opt/starrocks/be/log
```

Note that the specific `storageClassName` should be available in kubernetes cluster before enabling this storageVolume
feature. If `StorageVolume` info is not specified in CRD spec, the operator will use emptydir mode to store FE meta and
BE data.

## 2. Mounting Persistent Volumes by Helm Chart

See [helm_repo_add_howto](../install/add-helm-repo.md) to learn how to add the Helm Chart Repo for CelerData. In this
guide, we will use `celerdata/kube-celerdata` chart to deploy both CelerData operator and cluster.

### 2.1. Download the values.yaml file for the kube-celerdata chart

The values.yaml file contains the default configurations for the CelerData Operator and the CelerData cluster.

```bash
helm show values celerdata/kube-celerdata > values.yaml
```

The following is a snippet of the values.yaml file:

```yaml
celerdata:
  celerDataFeSpec: # fe storageSpec for persistent metadata.
    storageSpec:
      name: ""
      # the storageClassName represent the used storageclass name. if not set will use k8s cluster default storageclass.
      # you must set name when you set storageClassName
      # storageClassName: ""
      # the persistent volume size， default 10Gi.
      # fe container stop running if the disk free space which the fe meta directory residents, is less than 5Gi.
      storageSize: 10Gi
      # Setting this parameter can persist log storage
      logStorageSize: 5Gi

  celerDataBeSpec: # specify storageclass name and request size.
    storageSpec: # the name of volume for mount. if not will use emptyDir.
      name: ""
      # the storageClassName represent the used storageclass name. if not set will use k8s cluster default storageclass.
      # you must set name when you set storageClassName
      storageClassName: ""
      storageSize: 1Ti
      # Setting this parameter can persist log storage
      logStorageSize: 1Gi
```

### 2.2. Configure a YAML File with storageSpec settings

The following is an example of a custom values.yaml with storageSpec settings:

```yaml
celerdata:
   celerDataFeSpec:
      image:
         repository: us-west1-docker.pkg.dev/phrasal-verve-350013/celerdata/fe-ubuntu
         tag: 4.1-latest
      storageSpec:
         name: fe-data
         storageClassName: standard-rwo   # standard-rwo is the default storageClassName in GKE.
         logStorageSize: 10Gi
         storageSize: 100Gi
   celerDataBeSpec:
      image:
         repository: us-west1-docker.pkg.dev/phrasal-verve-350013/celerdata/be-ubuntu
         tag: 4.1-latest
      replicas: 3
      storageSpec:
         name: be-storage
         storageClassName: standard-rwo
         logStorageSize: 10Gi
         storageSize: 500Gi
```

### 2.3. Deploy CelerData Operator and Cluster

See [Install CelerData by kube-celerdata chart](../../../helm-charts/charts/kube-celerdata/README.md) to learn how to deploy
CelerData Operator and Cluster

For the special `emptyDir` and `hostPath` values, see
[Storage classes](../../reference/storage-classes.md).
