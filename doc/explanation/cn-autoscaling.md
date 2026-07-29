---
title: CN node autoscaling
sidebar_label: CN node autoscaling
sidebar_position: 4
description: Why CN nodes are the elastic tier, and what changed in the operator's HPA support in v1.11.0.
---

# CN node autoscaling

The HPA feature enables automatic scaling of CN nodes based on resource metrics such as CPU and memory utilization. CN nodes are designed for elastic scaling as they handle query processing without affecting data distribution.

## What changed in v1.11.0

Since v1.11.0, the following critical issues have been resolved:

- **Resource Cleanup**: Proper HPA resource management when autoscaling policies are removed
- **Version Compatibility**: Support for multiple HPA API versions across different Kubernetes versions
- **Graceful Scaling**: Coordinated scaling operations with proper node registration/deregistration
- **Conflict Resolution**: Eliminated conflicts between operator and HPA replica management

## Two deployment shapes

There are two ways to deploy CelerData with HPA-enabled CN nodes:

### Integrated CelerData Cluster with CN Nodes

Deploy a complete CelerData cluster including FE and CN nodes with HPA in a single chart.

### Separate Cluster and Warehouse Deployment

Deploy the main CelerData cluster first, then deploy separate Warehouse instances with HPA-enabled CN nodes.

For the procedures, see
[Autoscale CN nodes with HPA](../how-to/scale/autoscale-cn-nodes-with-hpa.md).
