# CelerData-Kubernetes-Operator

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

> English | [中文](README_ZH-CN.md)

## Overview

CelerData Kubernetes Operator is a project that implements the deployment and operation of CelerData, a next-generation
sub-second MPP OLAP database, on Kubernetes. It facilitates the deployment of CelerData' Frontend (FE), Backend (BE),
and Compute Node (CN) components within your Kubernetes environment. It also includes Helm chart for easy installation
and configuration. With CelerData Kubernetes Operator, you can easily manage the lifecycle of CelerData clusters, such
as installing, scaling, upgrading etc.

> [!NOTE]
> The CelerData k8s operator was designed to be a level 2 operator. See https://sdk.operatorframework.io/docs/overview/operator-capabilities/ to understand more about the capabilities of a level 2 operator.

## Documentation

**📖 <https://phoenixaidocsanywhere.vercel.app/Anywhere/>**

| | |
|---|---|
| **New here?** | [Run a cluster locally](./doc/tutorials/local-quickstart.md) — build one on your laptop in 20 minutes |
| **Installing?** | [Deploy with Helm](./doc/how-to/install/deploy-with-helm.md) or [deploy with the operator](./doc/how-to/install/deploy-with-operator.md) |
| **Looking something up?** | [CRD API reference](./doc/reference/api.md) · [Helm charts](./doc/reference/helm-charts.md) · [Example manifests](./doc/reference/examples.md) |
| **Want to understand it?** | [Explanation](./doc/explanation) — scaling behavior, disaster recovery, chart layout |

The [`doc/`](./doc) directory is the source for the documentation site and is organized by
[Diátaxis](https://diataxis.fr/): `tutorials/`, `how-to/`, `reference/`, `explanation/`.

## Prerequisites

1. Kubernetes version >= 1.23.0
2. Helm version >= 3.0

## Features

### Operator Features

- Support deploying CelerData FE, BE and CN components separately
  FE component is a must-have component, BE and CN components can be optionally deployed
- Support multiple CelerData clusters in one Kubernetes cluster
- Support external clients outside the network of kubernetes to load data into CelerData using STREAM LOAD
- Support automatic scaling for CN nodes based on CPU and memory usage
- Support mounting persistent volumes for CelerData containers

### Helm Chart Features

- Support Helm Chart for easy installation and configuration
    - using kube-celerdata Helm chart to install both operator and CelerData cluster
    - using operator Helm Chart to install operator, and using CelerData Helm Chart to install celerdata cluster
- Support initializing the password of root in your CelerData cluster during installation.
- Support integration with other components in the Kubernetes ecosystem, such as Prometheus, Datadog, etc.

## Installation

To use CelerData in Kubernetes you need three things: the `CelerDataCluster` CRD, the
CelerData Operator, and a `CelerDataCluster` resource. There are two ways to install them.

**With Helm** — one command installs the operator and a cluster together:

```bash
helm repo add celerdata https://celerdata.github.io/phoenixai-kubernetes-operator
helm repo update celerdata
helm install kube-celerdata celerdata/kube-celerdata -n celerdata --create-namespace
```

See [Deploy a cluster with Helm](./doc/how-to/install/deploy-with-helm.md).

**With YAML manifests** — apply the CRD, then the operator, then your cluster:

```bash
kubectl apply -f https://raw.githubusercontent.com/celerdata/phoenixai-kubernetes-operator/main/deploy/celerdata.com_celerdataclusters.yaml
kubectl apply -f https://raw.githubusercontent.com/celerdata/phoenixai-kubernetes-operator/main/deploy/operator.yaml
kubectl apply -f https://raw.githubusercontent.com/celerdata/phoenixai-kubernetes-operator/main/examples/celerdata/celerdata-fe-and-be.yaml
```

See [Deploy a cluster with the operator](./doc/how-to/install/deploy-with-operator.md) for
the full walkthrough, including custom namespaces and verification.

> [!NOTE]
> Every release ships the latest manifests and Helm charts. Find them at
> https://github.com/celerdata/phoenixai-kubernetes-operator/releases

Once installed, see [Access a cluster](./doc/how-to/operate/access-a-cluster.md) to connect,
and [Upgrade a cluster](./doc/how-to/operate/upgrade-a-cluster.md) to move to a new version.
