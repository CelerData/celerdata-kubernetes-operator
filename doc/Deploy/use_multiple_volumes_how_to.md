# Deploy PhoenixAI with Multiple Volumes

This document describes how to use multiple volumes to store PhoenixAI data.
> Note: After installation, you are not allowed to modify the volume related fields no matter in the CRD or Helm Chart.

# Deploy PhoenixAI with Multiple Volumes By Helm Chart

Based on the `storageSpec` field
in [values.yaml](https://github.com/CelerData/phoenixai-kubernetes-operator/blob/main/helm-charts/charts/kube-anywhere/values.yaml),
we will give an example of how to use multiple volumes to store PhoenixAI data.

```yaml
operator:
  phoenixAIOperator:
    image:
      repository: us-west1-docker.pkg.dev/phoenix-ai-images/enterprise/operator
      tag: v1.9.8
    imagePullPolicy: IfNotPresent
    resources:
      requests:
        cpu: 1m
        memory: 20Mi
phoenixai:
  phoenixAICnSpec:
    cnEnvVars:
    # add storage_root_path in PhoenixAI config
    config: |
      thrift_port = 9060
      webserver_port = 8040
      heartbeat_service_port = 9050
      brpc_port = 8060
      sys_log_level = INFO
      storage_root_path = /opt/starrocks/cn/storage0;/opt/starrocks/cn/storage1
    image:
      repository: us-west1-docker.pkg.dev/phoenix-ai-images/enterprise/cn-ubuntu
      tag: 4.1-latest
    replicas: 1
    resources:
      limits:
        cpu: 8
        memory: 8Gi
      requests:
        cpu: 1m
        memory: 10Mi
    storageSpec:
      logStorageSize: 1Gi
      name: cn-storage
      storageCount: 2   # specify the number of volumes
      storageSize: 10Gi # the size of each volume
  phoenixAIFeSpec:
    image:
      repository: us-west1-docker.pkg.dev/phoenix-ai-images/enterprise/fe-ubuntu
      tag: 4.1-latest
    resources:
      limits:
        cpu: 2
        memory: 4Gi
      requests:
        cpu: 1m
        memory: 20Mi
    storageSpec:
      logStorageSize: 1Gi
      name: fe
      storageSize: 10Gi
```

Note:

1. add `storage_root_path` field in PhoenixAI config.
2. use `storageCount` to specify the number of volumes.
3. the `storage` directory still exists in the container, but will not be used to store data.

## What if I want to use different storageClass or storageSize for each volume?

This feature is not supported in Helm Chart. The following is a workaround:

```bash
# phoenixai-community is a helm chart repository, you can show yours by `helm repo list`
# kube-anywhere is the name of the helm chart
helm template kube-anywhere phoenixai/kube-anywhere -f ./values.yaml >./sr.yaml

# From the sr.yaml, there will a Custom Resource Definition (CRD) named PhoenixAICluster.
# You can modify the CRD to use different storageClass or storageSize for each volume.
storageVolumes:
- name: cn0-data
storageClassName: "standard" # you can change the storageClassName
storageSize: "10Gi"          # you can change the storageSize
mountPath: /opt/starrocks/cn/storage0
- name: cn1-data
storageClassName: "standard"
storageSize: "10Gi"
mountPath: /opt/starrocks/cn/storage1
- name: cn-log
storageClassName:
storageSize: "1Gi"
mountPath: /opt/starrocks/cn/log
- name: cn-spill
storageClassName:
storageSize: "0Gi"
mountPath: /opt/starrocks/cn/spill

# After modifying the CRD, you can apply it to your Kubernetes cluster.
kubectl apply -f sr.yaml
```
