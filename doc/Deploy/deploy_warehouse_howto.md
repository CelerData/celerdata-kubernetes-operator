---
sidebar_position: 5
---

# Deploy Warehouse

From PhoenixAI Operator v1.9.0, PhoenixAIWarehouse CRD is introduced to manage the warehouse. This document describes
how to deploy a warehouse.

## 1. Prerequisites

1. PhoenixAI Operator >= v1.9.0. The latest version of the operator is recommended.
2. An installed PhoenixAI Cluster.
   See [deploy_phoenixai_with_operator_howto.md](./deploy_phoenixai_with_operator_howto.md)
   or [deploy_phoenixai_with_helm_howto.md](./deploy_phoenixai_with_helm_howto.md) for more details.
3. PhoenixAI enterprise version >= v3.2.0.

## 2. Deploy Warehouse

You can choose one of the following methods to deploy a warehouse:

1. Deploy Warehouse by YAML Manifest
2. Deploy Warehouse by Helm Chart

> The CN nodes you deploy with a PhoenixAI cluster are added to the `default_warehouse` by default. You can
> also define a Warehouse CR named `default-warehouse` to add more CN nodes to that warehouse.

### 2.1 Deploy Warehouse by YAML Manifest

First, we need to install PhoenixAIWarehouse CRD and restart the PhoenixAI operator to make it aware of the new CRD.

```console
# install crd
kubectl apply -f https://github.com/CelerData/phoenixai-kubernetes-operator/releases/download/v1.9.6/phoenixdata.ai_phoenixaiwarehouses.yaml

# restart operator
kubectl rollout restart deployment kube-anywhere-operator
```

Then, we need to deploy a warehouse by the following YAML manifest.

```yaml
# wh1.yaml
apiVersion: phoenixdata.ai/v1
kind: PhoenixAIWarehouse
metadata:
  # A warehouse will be created with this name in PhoenixAI Cluster. If you are using dash(-) in the name, the warehouse
  # name created by PhoenixAI will be replaced with underscore(_).
  name: wh1

spec:
  # Make sure the PhoenixAI cluster exists in the same namespace.
  # You can check it by running `kubectl -n phoenixai get phoenixaiclusters.phoenixdata.ai`.
  phoenixAICluster: kube-anywhere
  template:
    envVars:
      - name: TZ
        value: UTC
    image: us-west1-docker.pkg.dev/phoenix-ai-images/enterprise/cn-ubuntu:4.1.3-ee
    replicas: 1
    limits:
      cpu: 8
      memory: 8Gi
    requests:
      cpu: 8
      memory: 8Gi
```

You can see [api.md](../api.md) for more details about the PhoenixAIWarehouse CRD fields. The spec part is very similar
to the PhoenixAICnSpec of PhoenixAICluster, so
see [deploy_a_phoenixai_cluster_with_cn.yaml](../../examples/phoenixai/deploy_a_phoenixai_cluster_with_cn.yaml) for more
fields.

Apply the YAML manifest:

```bash
kubectl -n phoenixai apply -f wh1.yaml
```

### 2.2. Deploy Warehouse by Helm Chart

We also support deploying a warehouse by Helm chart.
You can also see [Warehouse Chart](../../helm-charts/charts/warehouse/README.md) for how to deploy it.

First, prepare a values.yaml file for Warehouse chart.

```yaml
# wh1-values.yaml
spec:
  # Make sure the PhoenixAI cluster exists in the same namespace.
  # You can check it by running `kubectl -n phoenixai get phoenixaiclusters.phoenixdata.ai`.
  phoenixAIClusterName: kube-anywhere
  replicas: 1
  image:
    repository: us-west1-docker.pkg.dev/phoenix-ai-images/enterprise/cn-ubuntu
    tag: "4.1.3-ee"
  resources:
    limits:
      cpu: 8
      memory: 8Gi
    requests:
      cpu: 8
      memory: 8Gi
```

Then deploy a warehouse by the following command:

```console
# Use the above values.yaml to deploy a warehouse in namespace phoenixai
helm -n phoenixai install wh1 phoenixai/warehouse -f wh1-values.yaml

# Restart the PhoenixAI operator to make it aware of the new CRD
kubectl -n phoenixai rollout restart deployment kube-anywhere-operator
```

## 3. Manage Warehouse

### 3.1. Show the deployed warehouse

If you have deployed the above warehouse, you can see it by using the following SQL command:

```console
# A warehouse has been created with the name `wh1`.
mysql> show warehouses;
+-------+-------------------+-----------+-----------+---------------------+-----------------+-----------------+------------+-----------+-----------+---------------------+---------------------+----------------------------------------------+
| Id    | Name              | State     | NodeCount | CurrentClusterCount | MaxClusterCount | StartedClusters | RunningSql | QueuedSql | CreatedOn | ResumedOn           | UpdatedOn           | Comment                                      |
+-------+-------------------+-----------+-----------+---------------------+-----------------+-----------------+------------+-----------+-----------+---------------------+---------------------+----------------------------------------------+
| 0     | default_warehouse | AVAILABLE | 0         | 1                   | 1               | 1               | 0          | 0         | NULL      | 2024-05-11 16:49:37 | 2024-05-11 17:53:30 | An internal warehouse init after FE is ready |
| 35030 | wh1               | AVAILABLE | 1         | 1                   | 1               | 1               | 0          | 0         | NULL      | NULL                | NULL                | NULL                                         |
+-------+-------------------+-----------+-----------+---------------------+-----------------+-----------------+------------+-----------+-----------+---------------------+---------------------+----------------------------------------------+
2 rows in set (0.00 sec)
```

### 3.2 Upgrade Deployment

We strongly recommend you to upgrade deployment by modifying the YAML Manifest file or values.yaml file. For example,
you can update any fields in the file, e.g. the image version, replicas, and resources.

> We don't suggest you to modify the deployment of warehouse by `kubectl edit`.

#### 3.2.1 Update the YAML manifest

For example, upgrade the image version:

```yaml
apiVersion: phoenixdata.ai/v1
kind: PhoenixAIWarehouse
metadata:
  # A warehouse will be created with this name in PhoenixAI Cluster. If you are using dash(-) in the name, the warehouse
  # name created by PhoenixAI will be replaced with underscore(_).
  name: wh1

spec:
  # Make sure the PhoenixAI cluster exists in the same namespace.
  # You can check it by running `kubectl -n phoenixai get phoenixaiclusters.phoenixdata.ai`.
  phoenixAICluster: kube-anywhere
  template:
    envVars:
      - name: TZ
        value: UTC
    image: us-west1-docker.pkg.dev/phoenix-ai-images/enterprise/cn-ubuntu:4.1.4-ee  # this line is updated
    replicas: 1
    limits:
      cpu: 8
      memory: 8Gi
    requests:
      cpu: 8
      memory: 8Gi
```

Apply the updated YAML manifest:

```console
kubectl -n phoenixai apply -f wh1.yaml
```

### 3.2.2 Update values.yaml for Helm chart

For example, upgrade the image version:

```yaml
# wh1-values.yaml
spec:
  # Make sure the PhoenixAI cluster exists in the same namespace.
  # You can check it by running `kubectl -n phoenixai get phoenixaiclusters.phoenixdata.ai`.
  phoenixAIClusterName: kube-anywhere
  replicas: 1
  image:
    repository: us-west1-docker.pkg.dev/phoenix-ai-images/enterprise/cn-ubuntu
    tag: "4.1.4-ee" # this line is updated
  resources:
    limits:
      cpu: 8
      memory: 8Gi
    requests:
      cpu: 8
      memory: 8Gi
```

Then upgrade the warehouse by the following command:

```console
helm -n phoenixai upgrade wh1 phoenixai/warehouse -f wh1-values.yaml
```

## 4. Delete the Warehouse

If you deployed the warehouse by YAML manifest, you can delete it by running the following command:

```console
kubectl delete -f wh1.yaml
```

If you deployed the warehouse by Helm chart, you can delete it by running the following command:

```console
helm -n phoenixai uninstall wh1
```
