---
title: Example manifests
sidebar_label: Example manifests
sidebar_position: 5
description: The sample CelerDataCluster manifests shipped in the repository, and what each one demonstrates.
---

# Example manifests

The [`examples/celerdata`](../../examples/celerdata) directory holds ready-to-apply
`CelerDataCluster` manifests. Use them as starting points and edit to taste.

| Manifest | Demonstrates |
| --- | --- |
| [`celerdata-fe-and-be.yaml`](../../examples/celerdata/celerdata-fe-and-be.yaml) | Three FE and three BE nodes — the manifest used by [Deploy a cluster with the operator](../how-to/install/deploy-with-operator.md) |
| [`deploy_a_celerdata_cluster_with_no_ha.yaml`](../../examples/celerdata/deploy_a_celerdata_cluster_with_no_ha.yaml) | The smallest possible cluster, single FE, no high availability |
| [`deploy_a_ha_celerdata_cluster.yaml`](../../examples/celerdata/deploy_a_ha_celerdata_cluster.yaml) | A highly available cluster with an FE quorum |
| [`deploy_a_celerdata_cluster_with_cn.yaml`](../../examples/celerdata/deploy_a_celerdata_cluster_with_cn.yaml) | Adding CN nodes, the elastically scalable compute tier |
| [`deploy_a_celerdata_cluster_with_custom_configurations.yaml`](../../examples/celerdata/deploy_a_celerdata_cluster_with_custom_configurations.yaml) | Overriding `fe.conf` and `be.conf` through ConfigMaps |
| [`deploy_a_celerdata_cluster_with_persistent_storage.yaml`](../../examples/celerdata/deploy_a_celerdata_cluster_with_persistent_storage.yaml) | `storageVolumes` for durable FE metadata and BE data |
| [`deploy_a_celerdata_cluster_running_in_shared_data_mode.yaml`](../../examples/celerdata/deploy_a_celerdata_cluster_running_in_shared_data_mode.yaml) | Shared-data mode, backed by object storage |
| [`deploy_a_celerdata_cluster_with_fe_proxy.yaml`](../../examples/celerdata/deploy_a_celerdata_cluster_with_fe_proxy.yaml) | The FE Proxy, needed to load data from outside the cluster network |
| [`deploy_a_celerdata_cluster_with_be_capabilities.yaml`](../../examples/celerdata/deploy_a_celerdata_cluster_with_be_capabilities.yaml) | Granting Linux capabilities to BE containers |
| [`deploy_a_celerdata_cluster_with_all_features.yaml`](../../examples/celerdata/deploy_a_celerdata_cluster_with_all_features.yaml) | Everything above combined in one manifest |

Some examples need editing before they will work. The shared-data example in particular
needs an object storage location and credentials — MinIO, S3, OSS, and so on. In these
manifests the values you need to change are usually inside a ConfigMap.

For every field these manifests can contain, see the [API reference](./api.md).
