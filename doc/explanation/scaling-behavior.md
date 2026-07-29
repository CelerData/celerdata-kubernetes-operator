---
title: Scaling behavior
sidebar_label: Scaling behavior
sidebar_position: 3
description: "Why scaling in needs care: FE quorum and BDBJE constraints, and how the operator handles BE replica reduction."
---

# Scaling behavior

Scaling *out* is safe and automatic. Scaling *in* is not — the operator reduces the
StatefulSet replica count and little else, so nodes must be deregistered from the cluster
first. This page explains why for each component.

## FE nodes and quorum

FE nodes in a CelerData cluster are used to store metadata. Normally, users do not need to scale in the FE nodes.
Incorrect operator may cause metadata inconsistency and malfunction. Be sure for every scale-in op, the number of the
offline FE nodes shall not be larger than the quorum. E.g. Don't try to scale-in directly from 7->3, user should first
scale-in 7->5, and then 5->3. For each scale in op, user should carefully check all the status of the remaining FE,
connect to the remaining FE node directly and run `SHOW FRONTENDS`, make sure all the FE nodes have consistent view of
the current FE nodes.

> Note: If you scale-in FE from 3->1, it will fail for sure, because the BDBJE HAGroup can't change from HA mode to
> single node mode automatically.

## BE nodes in a shared-nothing cluster

Unfortunately, the current implementation of CelerData Operator does not
follow [the standard operation](https://docs.starrocks.io/docs/administration/management/Scale_up_down/) defined by
CelerData. So this document introduces:

When users adjust the `replicas` field to a smaller number, CelerData Operator will **just modify the replicas field**
of the statefulset object.

For example, a user initially has 6 BE nodes:

```yaml
# because the statefulset name is kube-celerdata-be, the pod names are:
kube-celerdata-be-0
kube-celerdata-be-1
kube-celerdata-be-2
kube-celerdata-be-3
kube-celerdata-be-4
kube-celerdata-be-5
```

When the user scale in the cluster to 3 BE nodes, `kube-celerdata-be-5`, `kube-celerdata-be-4`, and
`kube-celerdata-be-3` pods will be deleted directly.

Because the pods are deleted outright, any data that lived only on the removed nodes is
lost. The PVCs survive, which is what makes the recovery in
[Scale in BE nodes](../how-to/scale/scale-in-be-nodes.md) possible.

For the correct procedures, see [Scale in FE nodes](../how-to/scale/scale-in-fe-nodes.md)
and [Scale in BE nodes](../how-to/scale/scale-in-be-nodes.md).
