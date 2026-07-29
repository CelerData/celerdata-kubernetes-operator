---
title: Scale out a cluster
sidebar_label: Scale out
sidebar_position: 1
description: Add BE and FE nodes to a running cluster, and the limits that apply when scaling FE back in.
---

# Scale out a cluster

This topic takes scaling out the BE and FE clusters as examples.

## Scale out BE cluster

Run the following command to scale out the BE cluster to 9 nodes:

```bash
kubectl -n celerdata patch celerdatacluster celerdatacluster-sample --type='merge' -p '{"spec":{"celerDataBeSpec":{"replicas":9}}}'
```

## Scale out FE cluster

Run the following command to scale out the FE cluster to 4 nodes:

```bash
kubectl -n celerdata patch celerdatacluster celerdatacluster-sample --type='merge' -p '{"spec":{"celerDataFeSpec":{"replicas":4}}}'
```

The scaling process lasts for a while. You can use the command `kubectl -n celerdata get pods` to view the scaling
progress.

**Add cautions on scale-in FE nodes**:

FE nodes can be scaled-in, but there are some limitations:

1. FE nodes can only be scaled-in step by step. If the last scale-in operation is not completed, the next scale-in
   operation cannot be performed.
2. Each time less than half of the nodes can be scaled-in.
3. You can't do 3->1 scale in.

To scale *in* rather than out, see [Scale in FE nodes](./scale-in-fe-nodes.md) and
[Scale in BE nodes](./scale-in-be-nodes.md) — both need a deregistration step first.
