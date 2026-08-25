# Documentation

Guides for deploying and operating PhoenixAI on Kubernetes, grouped by topic.
These are the same guides that make up the PhoenixAI Anywhere documentation
site.

## Get started

- [Console tour](./GetStarted/anywhere_console_ui_guide.md)
- [Add the Helm Chart Repo for PhoenixAI](./GetStarted/add_helm_repo_howto.md)
- [Least Permission to Deploy PhoenixAI](./GetStarted/least_permission_to_deploy_phoenixai_howto.md)
- [Migrate from the Open-Source StarRocks Operator to PhoenixAI](./GetStarted/migrate-from-starrocks-howto.md)

## Quick starts

- [Quick start with Amazon S3](./QuickStart/quickstart_s3.md)
- [Quick start with MinIO](./QuickStart/quickstart_minio.md)

## Deploy

- [Deploy PhoenixAI With Operator](./Deploy/deploy_phoenixai_with_operator_howto.md)
- [Deploy PhoenixAI With Helm](./Deploy/deploy_phoenixai_with_helm_howto.md)
- [Deploy Multiple Clusters](./Deploy/deploy_multiple_clusters_howto.md)
- [Deploy a Warehouse](./Deploy/deploy_warehouse_howto.md)
- [Upgrade the Operator](./Deploy/upgrade_operator_howto.md)
- [Use Multiple Volumes](./Deploy/use_multiple_volumes_how_to.md)

## Configure

- [Change Root Password](./Configure/change_root_password_howto.md)
- [Init Root Password When First Deploy](./Configure/initialize_root_password_howto.md)
- [Connect the Operator to an SSL-Enabled FE](./Configure/connect_to_ssl_enabled_fe_howto.md)
- [Mount Persistent Volume](./Configure/mount_persistent_volume_howto.md)
- [Mount CSI Ephemeral Volumes](./Configure/mount_csi_volumes_howto.md)
- [Mount External ConfigMaps Or Secrets](./Configure/mount_external_configmaps_or_secrets_howto.md)
- [Run With a Read-Only Root Filesystem](./Configure/setup-phoenixai-when-readOnlyRootFilesystem-is-true.md)

## Scale

- [Automatic Scaling For CN Nodes](./Scale/automatic_scaling_for_cn_nodes_howto.md)
- [HPA Automatic Scaling For CN Nodes](./Scale/hpa_dynamic_scaling_with_helm_howto.md)
- [Scale In FE Nodes](./Scale/scale_in_fe_nodes_howto.md)

## Operate

- [Load Data Using Stream Load](./Operate/load_data_using_stream_load_howto.md)
- [Logging and Related Configurations](./Operate/logging_and_related_configurations_howto.md)
- [Expand Persistent Volume (FE/CN)](./Operate/expand_persistent_volume_howto.md)
- [Kubernetes Node Maintenance and PodDisruptionBudget](./Operate/node_maintenance_and_pdb_howto.md)
- [Disaster Recovery for a Shared-Data Cluster](./Operate/disaster_recovery_for_shared_data_cluster_howto.md)

## Monitor

- [Deploy Prometheus and Grafana](./Monitor/deploy-prometheus-grafana.md)
- [Prometheus And Grafana](./Monitor/integration-prometheus-grafana.md)
- [Anywhere Console monitoring](./Monitor/anywhere-monitoring.md)
- [Datadog](./Monitor/integration-with-datadog.md)

## How-to Guides

- [Use MinIO for Shared Data](./how-to/use_minio_for_shared_data_howto.md)

## Reference

- [API Reference](./api.md) — every field of the `PhoenixAICluster` and
  `PhoenixAIWarehouse` CRDs.

## Also in this folder

- [`deprecated/`](./deprecated) — documents resources that are no longer shipped.
