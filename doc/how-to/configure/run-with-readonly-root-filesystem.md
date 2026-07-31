---
title: Run with a read-only root filesystem
sidebar_label: Read-only root filesystem
sidebar_position: 9
description: Configure FE and BE to start when readOnlyRootFilesystem is true, with the CRD or with Helm.
---

# Run with a read-only root filesystem

Setting `readOnlyRootFilesystem: true` on its own stops FE and BE from starting: they write
into their own install directories, and a read-only root denies that. The fix is to mount a
writable volume, copy the install tree into it at startup, and point `STARROCKS_ROOT` there.

Requires operator and chart version v1.9.9 or later.

Both approaches below produce the same result — pick the one matching how you deploy. There
is a lot of YAML here and most of it is load-bearing, so [what these settings are actually
doing](#what-these-settings-do) is spelled out at the end rather than in comments.

There are two ways to deploy CelerData cluster:

1. Deploy CelerData cluster with `CelerDataCluster` CR yaml.
2. Deploy CelerData cluster with Helm chart.

Therefore, there are two ways to set up CelerData when the `readOnlyRootFilesystem` field is set to `true`.

## By using CelerDataCluster CR yaml

```yaml
apiVersion: celerdata.com/v1
kind: CelerDataCluster
metadata:
  name: kube-celerdata
  namespace: celerdata
spec:
  celerDataFeSpec:
    readOnlyRootFilesystem: true
    runAsNonRoot: true
    configMapInfo:
      configMapName: kube-celerdata-fe-cm
      resolveKey: fe.conf
    storageVolumes:
    - mountPath: /opt/starrocks-artifacts
      name: fe-artifacts
      storageClassName: emptyDir
      storageSize: 20Gi
    - mountPath: /opt/starrocks-meta
      name: fe-meta   # must be this
      storageSize: 10Gi
    - mountPath: /opt/starrocks-log
      name: fe-log    # must be this
      storageSize: 10Gi
    command: ["bash", "-c"]
    args:
      - cp -r /opt/starrocks/* /opt/starrocks-artifacts && exec /opt/starrocks-artifacts/fe_entrypoint.sh $FE_SERVICE_NAME
    feEnvVars:
    - name: STARROCKS_ROOT
      value: /opt/starrocks-artifacts
    image: us-west1-docker.pkg.dev/phrasal-verve-350013/celerdata/fe-ubuntu:3.2.2
    imagePullPolicy: IfNotPresent
    replicas: 1
    requests:
      cpu: 1m
      memory: 22Mi
  celerDataBeSpec:
    readOnlyRootFilesystem: true
    runAsNonRoot: true
    configMapInfo:
      configMapName: kube-celerdata-be-cm
      resolveKey: be.conf
    storageVolumes:
    - mountPath: /opt/starrocks-artifacts
      name: be-artifacts
      storageClassName: emptyDir
      storageSize: 20Gi
    - mountPath: /opt/starrocks-storage
      name: be-storage  # must be this
      storageSize: 10Gi
    - mountPath: /opt/starrocks-log
      name: be-log  # must be this
      storageSize: 10Gi
    command: ["bash", "-c"]
    args:
      - cp -r /opt/starrocks/* /opt/starrocks-artifacts && exec /opt/starrocks-artifacts/be_entrypoint.sh $FE_SERVICE_NAME
    beEnvVars:
    - name: STARROCKS_ROOT
      value: /opt/starrocks-artifacts
    image: us-west1-docker.pkg.dev/phrasal-verve-350013/celerdata/be-ubuntu:3.2.2
    imagePullPolicy: IfNotPresent
    replicas: 2
    requests:
      cpu: 1m
      memory: 10Mi

---

apiVersion: v1
data:
  fe.conf: |
    LOG_DIR = ${STARROCKS_HOME}/log
    DATE = "$(date +%Y%m%d-%H%M%S)"
    JAVA_OPTS="-Dlog4j2.formatMsgNoLookups=true -Xmx8192m -XX:+UseG1GC -Xlog:gc*:${LOG_DIR}/fe.gc.log.$DATE:time"
    http_port = 8030
    rpc_port = 9020
    query_port = 9030
    edit_log_port = 9010
    mysql_service_nio_enabled = true
    sys_log_level = INFO
    
    # config for meta and log
    meta_dir = /opt/starrocks-meta
    dump_log_dir = /opt/starrocks-log
    sys_log_dir = /opt/starrocks-log
    audit_log_dir = /opt/starrocks-log
kind: ConfigMap
metadata:
  name: kube-celerdata-fe-cm
  namespace: celerdata

---

apiVersion: v1
data:
  be.conf: |
    be_port = 9060
    webserver_port = 8040
    heartbeat_service_port = 9050
    brpc_port = 8060
    sys_log_level = INFO
    default_rowset_type = beta

    # config for storage and log
    storage_root_path = /opt/starrocks-storage
    sys_log_dir = /opt/starrocks-log
kind: ConfigMap
metadata:
  name: kube-celerdata-be-cm
  namespace: celerdata
```

## By using Helm Chart

If you are using the `kube-celerdata` Helm chart, add the following snippets to `values.yaml`.

> Note: you should use the chart version `v1.9.9` or later.

```yaml
operator:
  celerDataOperator:
    image:
      repository: us-west1-docker.pkg.dev/phrasal-verve-350013/celerdata/operator
      tag: v1.9.9
    imagePullPolicy: IfNotPresent
    resources:
      requests:
        cpu: 1m
        memory: 20Mi
celerdata:
  celerDataFeSpec:
    readOnlyRootFilesystem: true
    runAsNonRoot: true
    storageSpec:
      name: fe  # must be this
      storageSize: 10Gi
      storageMountPath: /opt/starrocks-meta
      logStorageSize: 10Gi
      logMountPath: /opt/starrocks-log
    emptyDirs:
    - name: fe-artifacts
      mountPath: /opt/starrocks-artifacts
    entrypoint:
      script: |
        #! /bin/bash
        cp -r /opt/starrocks/* /opt/starrocks-artifacts
        exec /opt/starrocks/fe_entrypoint.sh $FE_SERVICE_NAME
    feEnvVars:
    - name: STARROCKS_ROOT
      value: /opt/starrocks-artifacts
    image:
      repository: us-west1-docker.pkg.dev/phrasal-verve-350013/celerdata/fe-ubuntu
      tag: 3.2.2
    resources:
      limits:
        cpu: 2
        memory: 4Gi
      requests:
        cpu: 1m
        memory: 20Mi
    config: |
      LOG_DIR = ${STARROCKS_HOME}/log
      DATE = "$(date +%Y%m%d-%H%M%S)"
      JAVA_OPTS="-Dlog4j2.formatMsgNoLookups=true -Xmx8192m -XX:+UseG1GC -Xlog:gc*:${LOG_DIR}/fe.gc.log.$DATE:time"
      http_port = 8030
      rpc_port = 9020
      query_port = 9030
      edit_log_port = 9010
      mysql_service_nio_enabled = true
      sys_log_level = INFO
      # config for meta and log
      meta_dir = /opt/starrocks-meta
      dump_log_dir = /opt/starrocks-log
      sys_log_dir = /opt/starrocks-log
      audit_log_dir = /opt/starrocks-log
  celerDataBeSpec:
    readOnlyRootFilesystem: true
    runAsNonRoot: true
    storageSpec:
      name: be  # must be this
      storageSize: 10Gi
      storageMountPath: /opt/starrocks-storage
      logStorageSize: 10Gi
      logMountPath: /opt/starrocks-log
      spillStorageSize: 10Gi
      spillMountPath: /opt/starrocks-spill
    emptyDirs:
    - name: be-artifacts
      mountPath: /opt/starrocks-artifacts
    entrypoint:
      script: |
        #! /bin/bash
        cp -r /opt/starrocks/* /opt/starrocks-artifacts 
        exec /opt/starrocks-artifacts/be_entrypoint.sh $FE_SERVICE_NAME
    beEnvVars:
    - name: STARROCKS_ROOT
      value: /opt/starrocks-artifacts
    image:
      repository: us-west1-docker.pkg.dev/phrasal-verve-350013/celerdata/be-ubuntu
      tag: 3.2.2
    replicas: 1
    resources:
      limits:
        cpu: 8
        memory: 8Gi
      requests:
        cpu: 1m
        memory: 10Mi
    config: |
      be_port = 9060
      webserver_port = 8040
      heartbeat_service_port = 9050
      brpc_port = 8060
      sys_log_level = INFO
      default_rowset_type = beta
      # config for storage and log
      storage_root_path = /opt/starrocks-storage
      sys_log_dir = /opt/starrocks-log
      spill_local_storage_dir = /opt/starrocks-spill
```

## What these settings do

The manifests above are long. Here is what each moving part is for, now that you have one
applied.

**Why it fails without this.** `readOnlyRootFilesystem: true` is a good default — a
compromised process cannot rewrite its own binaries. But FE and BE both write inside their
install trees: FE creates `plugins/` and `temp_dir/`, writes `fe.pid` into `bin/`, and
resolves `conf/fe.conf` through a symlink; BE creates `spill/`, writes `be.pid`, and
populates `lib/jdbc_drivers`, `lib/small_file`, `lib/udf`, and `lib/udf-runtime`. All of
that lands on the root filesystem, so all of it is denied.

**The copy-at-startup trick.** The `emptyDir` mounted at `/opt/starrocks-artifacts` is
writable even when the root is not. The `entrypoint`/`args` override copies the whole
install tree into it, then executes the real entrypoint from there. Setting `STARROCKS_ROOT`
to that path is what makes the component treat the copy as its home. The root filesystem
stays read-only; the component gets somewhere to write.

**Why the volume names are fixed.** `fe-meta`, `fe-log`, `be-storage`, and `be-log` are the
names the operator looks for when wiring up metadata, data, and log storage — the `# must be
this` comments are not stylistic. Rename them and the operator will not recognise them.

**Why the ConfigMaps are mandatory here.** The defaults point FE's metadata and log
directories, and BE's `storage_root_path`, at paths inside the install tree — which is now a
throwaway copy on an `emptyDir`. The `meta_dir`, `sys_log_dir`, `audit_log_dir`, and
`storage_root_path` overrides move them onto the persistent volumes. Skip this and the
cluster starts, appears healthy, and loses its metadata and data on the next restart. That
failure is much worse than not starting at all, which is why the config override is part of
the procedure rather than an optional extra.

Note the asymmetry in the `emptyDir` sizes: `/opt/starrocks-artifacts` only holds a copy of
the install tree, while the metadata, data, and log volumes hold state that has to outlive
the pod.
