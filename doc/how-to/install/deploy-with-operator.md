---
title: Deploy a cluster with the operator
sidebar_label: Deploy with the operator
sidebar_position: 1
description: Install the CelerDataCluster CRD, deploy the operator, and create your first cluster with kubectl.
---

# Deploy a cluster with the operator

This document introduces how to use the CelerData Operator to automate the deployment and management of a CelerData
cluster on a Kubernetes cluster.

It includes the following parts:

1. Deploy CelerData Operator
2. Deploy CelerData cluster
3. Manage CelerData Cluster
    1. Access CelerData cluster
    2. Upgrade CelerData cluster
    3. Scale CelerData cluster
    4. Using ConfigMap to configure your CelerData cluster

> [!NOTE]
> The CelerData k8s operator was designed to be a level 2 operator.   See https://sdk.operatorframework.io/docs/overview/operator-capabilities/ to understand more about the capabilities of a level 2 operator.

## Prerequisites

1. Kubernetes cluster version >= 1.23.0+
2. kubelet version >= 1.23.0+

## 1. Deploy CelerData Operator

It includes the following main steps:

1. Apply CelerDataCluster CRD.
2. Deploy CelerData Operator.

### 1.1. Apply CelerDataCluster CRD

CelerDataCluster CRD is a custom resource definition (CRD) that defines the CelerData cluster. It is used to create and
manage CelerData clusters by using the CelerData Operator. Please refer to [api.md](../../reference/api.md) for the detailed
description of the CelerDataCluster CRD.

Apply the CelerDataCluster CRD by using the following command:

```bash
kubectl apply -f https://raw.githubusercontent.com/celerdata/phoenixai-kubernetes-operator/main/deploy/celerdata.com_celerdataclusters.yaml
```

### 1.2. Deploy CelerData Operator

You can choose to deploy the CelerData Operator by using a default configuration file or a custom configuration file.

1. **Deploy the CelerData Operator by using a default configuration file.**
   ```bash
   kubectl apply -f https://raw.githubusercontent.com/celerdata/phoenixai-kubernetes-operator/main/deploy/operator.yaml
   ```
   The CelerData Operator is deployed to the namespace `celerdata` and manages all CelerData clusters under all
   namespaces. After `operator.yaml` is applied, The following resources will be created:
    ```bash
    namespace/celerdata created
    serviceaccount/celerdata created
    clusterrole.rbac.authorization.k8s.io/kube-celerdata-operator created
    clusterrolebinding.rbac.authorization.k8s.io/kube-celerdata-operator created
    role.rbac.authorization.k8s.io/celerdata-leader-election-role created
    rolebinding.rbac.authorization.k8s.io/celerdata-leader-election-rolebinding created
    deployment.apps/kube-celerdata-operator created
    ```
2. **Deploy the CelerData Operator by using a custom configuration file.** By default, the Operator is configured to
   install in the celerdata namespace. To use the Operator in a custom namespace, download the Operator manifest and
   substitute all instances of namespace to your custom namespace.
    1. Download the configuration file **operator.yaml**, which is used to deploy the CelerData Operator.
       ```bash
       curl -O https://raw.githubusercontent.com/celerdata/phoenixai-kubernetes-operator/main/deploy/operator.yaml
       ```
    2. Modify the configuration file **operator.yaml** to suit your needs.
    3. Deploy the CelerData Operator.
       ```bash
       kubectl apply -f operator.yaml
       ```

3. **Check the running status of the CelerData Operator.** If the pod is in the `Running` state and all containers
   inside the pod are `READY`, the CelerData Operator is running as expected.

    ```bash
    $ kubectl -n celerdata get pods
    NAME                                  READY   STATUS    RESTARTS   AGE
    celerdata-controller-65bb8679-jkbtg   1/1     Running   0          5m6s
    ```

## 2. Deploy CelerData Cluster

You need to prepare a separate yaml file to deploy the CelerData FE, BE and CN components. You can directly use
the [sample configuration files](https://github.com/celerdata/phoenixai-kubernetes-operator/tree/main/examples/celerdata)
provided by CelerData to deploy a CelerData cluster (an object instantiated by using the custom resource CelerData
Cluster). For example, you can use **celerdata-fe-and-be.yaml** to deploy a CelerData cluster that consists of three FE
nodes and three BE nodes.

```bash
kubectl apply -f https://raw.githubusercontent.com/celerdata/phoenixai-kubernetes-operator/main/examples/celerdata/celerdata-fe-and-be.yaml
```

The following table describes a few important fields in the **celerdata-fe-and-be.yaml** file.

| **Field** | **Description** |
| --- | --- |
| Kind | The resource type of the object. The value must be `CelerDataCluster`. |
| Metadata | Metadata, in which the following sub-fields are nested:<ul><li>`name`: the name of the object. Each object name uniquely identifies an object of the same resource type.</li><li>`namespace`: the namespace to which the object belongs.</li></ul> |
| Spec | The expected status of the object. Valid values are `celerDataFeSpec`, `celerDataBeSpec`, and `celerDataCnSpec`. |

You can also deploy the CelerData cluster by using a modified configuration file. For supported fields and detailed
descriptions, see [api.md](https://github.com/celerdata/phoenixai-kubernetes-operator/blob/main/doc/api.md).

Deploying the CelerData cluster takes a while. During this period, you can use the
command `kubectl -n celerdata get pods` to check the starting status of the CelerData cluster. If all the pods are in
the `Running` state and all containers inside the pods are `READY`, the CelerData cluster is running as expected.

> **NOTE**
>
> If you customize the namespace in which the CelerData cluster is located, you need to replace `celerdata` with the
> name of your customized namespace.

```bash
$ kubectl -n celerdata get pods
NAME                                  READY   STATUS    RESTARTS   AGE
celerdata-controller-65bb8679-jkbtg   1/1     Running   0          22h
celerdatacluster-sample-be-0          1/1     Running   0          23h
celerdatacluster-sample-be-1          1/1     Running   0          23h
celerdatacluster-sample-be-2          1/1     Running   0          22h
celerdatacluster-sample-fe-0          1/1     Running   0          21h
celerdatacluster-sample-fe-1          1/1     Running   0          21h
celerdatacluster-sample-fe-2          1/1     Running   0          22h
```

> **Note**
>
> If some pods cannot be up after a long period of time, you can use `kubectl logs -n celerdata <pod_name>` to view the
> log information or use `kubectl -n celerdata describe pod <pod_name>` to view the event information to address the
> problem.

## Next steps

- [Access the cluster](../operate/access-a-cluster.md)
- [Upgrade the cluster](../operate/upgrade-a-cluster.md)
- [Scale the cluster out](../scale/scale-out-a-cluster.md)
- [Override component configuration files](../configure/override-component-config.md)

## FAQ

**Issue description:** When a custom resource CelerDataCluster is installed using `kubectl apply -f xxx`, an error is
returned `The CustomResourceDefinition 'celerdataclusters.celerdata.com' is invalid: metadata.annotations: Too long: must have at most 262144 bytes`.

**Cause analysis:** Whenever `kubectl apply -f xxx` is used to create or update resources, a metadata
annotation `kubectl.kubernetes.io/last-applied-configuration` is added. This metadata annotation is in JSON format and
records the *last-applied-configuration*. `kubectl apply -f xxx`" is suitable for most cases, but in rare situations ,
such as when the configuration file for the custom resource is too large, it may cause the size of the metadata
annotation to exceed the limit.

**Solution:** If you install the custom resource CelerDataCluster for the first time, it is recommended to
use `kubectl create -f xxx`. If the custom resource CelerDataCluster is already installed in the environment, and you
need to update its configuration, it is recommended to use `kubectl replace -f xxx`.
