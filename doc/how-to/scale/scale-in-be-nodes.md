---
title: Scale in BE nodes
sidebar_label: Scale in BE nodes
sidebar_position: 3
description: Decommission BE nodes in a shared-nothing cluster correctly, and recover if you already scaled in the wrong way.
---

# Scale in BE nodes

Applies to `shared-nothing` clusters. **Decommission each node before you reduce
`replicas`** — lowering `replicas` on its own deletes pods immediately and takes their data
with them.

If you have already scaled in the wrong way, start with the recovery below; it usually
works. The correct procedure follows it, and [why the two differ](#why-decommissioning-first-matters)
is at the end.

## Recover from an incorrect scale-in

Because CelerData Operator does not follow the standard operation defined by CelerData, if users scale in the
`shared-nothing` cluster, e.g. 6-->3, the data in the deleted BE nodes will be lost.

Because Operator did not delete the persistent volume claims (PVCs) of the deleted BE nodes, users can
recover the data by resetting the replicas field to the original number, e.g. 3-->6.

## Scale in correctly

To scale in the `shared-nothing` cluster correctly, users should follow the standard operation defined by CelerData. For
example, if users want to scale in the BE nodes from 6 to 3, they should scale in the BE nodes one by one.

1. Execute the `SHOW BACKENDS` command to get the BE nodes information, and must choose the
   `kube-celerdata-be-5.kube-celerdata-be-search.default.svc.cluster.local` node with the highest ordinal to be removed
   first.

   ```sql
   mysql
   > SHOW BACKENDS;
   +-----------+------------------------------------------------------------------------+---------------+--------+----------+----------+---------------------+---------------------+-------+----------------------+-----------------------+-----------+------------------+---------------+---------------+---------+----------------+--------+----------------+--------------------------------------------------------+-------------------+-------------+----------+----------+-------------------+------------+------------+---------------------------------------------------+----------+
   | BackendId | IP                                                                     | HeartbeatPort | BePort | HttpPort | BrpcPort | LastStartTime       | LastHeartbeat       | Alive | SystemDecommissioned | ClusterDecommissioned | TabletNum | DataUsedCapacity | AvailCapacity | TotalCapacity | UsedPct | MaxDiskUsedPct | ErrMsg | Version        | Status                                                 | DataTotalCapacity | DataUsedPct | CpuCores | MemLimit | NumRunningQueries | MemUsedPct | CpuUsedPct | DataCacheMetrics                                  | Location |
   +-----------+------------------------------------------------------------------------+---------------+--------+----------+----------+---------------------+---------------------+-------+----------------------+-----------------------+-----------+------------------+---------------+---------------+---------+----------------+--------+----------------+--------------------------------------------------------+-------------------+-------------+----------+----------+-------------------+------------+------------+---------------------------------------------------+----------+
   | 10003     | kube-celerdata-be-0.kube-celerdata-be-search.default.svc.cluster.local | 9050          | 9060   | 8040     | 8060     | 2025-10-17 03:05:43 | 2025-10-17 04:13:34 | true  | false                | false                 | 41        | 0.000 B          | 76.209 GB     | 182.280 GB    | 58.19 % | 58.19 %        |        | 3.3.10-227b0b3 | {"lastSuccessReportTabletsTime":"2025-10-17 04:12:47"} | 76.209 GB         | 0.00 %      | 8        | 6.207GB  | 0                 | 2.86 %     | 0.2 %      | Status: Normal, DiskUsage: 0B/0B, MemUsage: 0B/0B |          |
   | 10002     | kube-celerdata-be-1.kube-celerdata-be-search.default.svc.cluster.local | 9050          | 9060   | 8040     | 8060     | 2025-10-17 03:05:43 | 2025-10-17 04:13:34 | true  | false                | false                 | 42        | 0.000 B          | 76.209 GB     | 182.280 GB    | 58.19 % | 58.19 %        |        | 3.3.10-227b0b3 | {"lastSuccessReportTabletsTime":"2025-10-17 04:12:47"} | 76.209 GB         | 0.00 %      | 8        | 6.207GB  | 0                 | 2.89 %     | 0.2 %      | Status: Normal, DiskUsage: 0B/0B, MemUsage: 0B/0B |          |
   | 10001     | kube-celerdata-be-2.kube-celerdata-be-search.default.svc.cluster.local | 9050          | 9060   | 8040     | 8060     | 2025-10-17 03:05:43 | 2025-10-17 04:13:34 | true  | false                | false                 | 41        | 0.000 B          | 76.209 GB     | 182.280 GB    | 58.19 % | 58.19 %        |        | 3.3.10-227b0b3 | {"lastSuccessReportTabletsTime":"2025-10-17 04:12:47"} | 76.209 GB         | 0.00 %      | 8        | 6.207GB  | 0                 | 2.87 %     | 0.2 %      | Status: Normal, DiskUsage: 0B/0B, MemUsage: 0B/0B |          |
   | 10004     | kube-celerdata-be-3.kube-celerdata-be-search.default.svc.cluster.local | 9050          | 9060   | 8040     | 8060     | 2025-10-17 03:05:43 | 2025-10-17 04:13:34 | true  | false                | false                 | 42        | 0.000 B          | 76.209 GB     | 182.280 GB    | 58.19 % | 58.19 %        |        | 3.3.10-227b0b3 | {"lastSuccessReportTabletsTime":"2025-10-17 04:12:47"} | 76.209 GB         | 0.00 %      | 8        | 6.207GB  | 0                 | 2.88 %     | 0.1 %      | Status: Normal, DiskUsage: 0B/0B, MemUsage: 0B/0B |          |
   | 10005     | kube-celerdata-be-4.kube-celerdata-be-search.default.svc.cluster.local | 9050          | 9060   | 8040     | 8060     | 2025-10-17 03:05:43 | 2025-10-17 04:13:34 | true  | false                | false                 | 41        | 0.000 B          | 76.209 GB     | 182.280 GB    | 58.19 % | 58.19 %        |        | 3.3.10-227b0b3 | {"lastSuccessReportTabletsTime":"2025-10-17 04:12:47"} | 76.209 GB         | 0.00 %      | 8        | 6.207GB  | 0                 | 2.88 %     | 0.2 %      | Status: Normal, DiskUsage: 0B/0B, MemUsage: 0B/0B |          |
   | 10312     | kube-celerdata-be-5.kube-celerdata-be-search.default.svc.cluster.local | 9050          | 9060   | 8040     | 8060     | 2025-10-17 04:13:24 | 2025-10-17 04:13:34 | true  | false                | false                 | 0         | 0.000 B          | 75.922 GB     | 182.280 GB    | 58.35 % | 58.35 %        |        | 3.3.10-227b0b3 | {"lastSuccessReportTabletsTime":"2025-10-17 04:13:25"} | 75.922 GB         | 0.00 %      | 8        | 6.207GB  | 0                 | 2.81 %     | 0.4 %      | Status: Normal, DiskUsage: 0B/0B, MemUsage: 0B/0B |          |
   +-----------+------------------------------------------------------------------------+---------------+--------+----------+----------+---------------------+---------------------+-------+----------------------+-----------------------+-----------+------------------+---------------+---------------+---------+----------------+--------+----------------+--------------------------------------------------------+-------------------+-------------+----------+----------+-------------------+------------+------------+---------------------------------------------------+----------+
   6 rows in set (0.02 sec)
   ```

2. Set the `drop_backend_after_decommission` configuration to `false` to avoid automatic deletion of the backend after
   decommissioning.

   ```sql
   ADMIN SET FRONTEND CONFIG ("drop_backend_after_decommission" = "false");
   ```

3. Execute the command to decommission the chosen BE node.

   ```sql
   ALTER SYSTEM DECOMMISSION BACKEND "kube-celerdata-be-5.kube-celerdata-be-search.default.svc.cluster.local:9050"
   ```

4. Execute the `SHOW BACKENDS` command to check the decommission status of the BE node(
   kube-celerdata-be-5.kube-celerdata-be-search.default.svc.cluster.local). If the value of `SystemDecommissioned` field
   is true and `TabletNum` is 0, the BE node is decommissioned successfully.

   ```sql
   mysql> SHOW BACKENDS;
   +-----------+------------------------------------------------------------------------+---------------+--------+----------+----------+---------------------+---------------------+-------+----------------------+-----------------------+-----------+------------------+---------------+---------------+---------+----------------+--------+----------------+--------------------------------------------------------+-------------------+-------------+----------+----------+-------------------+------------+------------+---------------------------------------------------+----------+
   | BackendId | IP                                                                     | HeartbeatPort | BePort | HttpPort | BrpcPort | LastStartTime       | LastHeartbeat       | Alive | SystemDecommissioned | ClusterDecommissioned | TabletNum | DataUsedCapacity | AvailCapacity | TotalCapacity | UsedPct | MaxDiskUsedPct | ErrMsg | Version        | Status                                                 | DataTotalCapacity | DataUsedPct | CpuCores | MemLimit | NumRunningQueries | MemUsedPct | CpuUsedPct | DataCacheMetrics                                  | Location |
   +-----------+------------------------------------------------------------------------+---------------+--------+----------+----------+---------------------+---------------------+-------+----------------------+-----------------------+-----------+------------------+---------------+---------------+---------+----------------+--------+----------------+--------------------------------------------------------+-------------------+-------------+----------+----------+-------------------+------------+------------+---------------------------------------------------+----------+
   | 10003     | kube-celerdata-be-0.kube-celerdata-be-search.default.svc.cluster.local | 9050          | 9060   | 8040     | 8060     | 2025-10-17 03:05:43 | 2025-10-17 04:24:39 | true  | false                | false                 | 41        | 0.000 B          | 75.850 GB     | 182.280 GB    | 58.39 % | 58.39 %        |        | 3.3.10-227b0b3 | {"lastSuccessReportTabletsTime":"2025-10-17 04:23:48"} | 75.850 GB         | 0.00 %      | 8        | 6.207GB  | 0                 | 2.87 %     | 0.1 %      | Status: Normal, DiskUsage: 0B/0B, MemUsage: 0B/0B |          |
   | 10002     | kube-celerdata-be-1.kube-celerdata-be-search.default.svc.cluster.local | 9050          | 9060   | 8040     | 8060     | 2025-10-17 03:05:43 | 2025-10-17 04:24:39 | true  | false                | false                 | 41        | 0.000 B          | 75.850 GB     | 182.280 GB    | 58.39 % | 58.39 %        |        | 3.3.10-227b0b3 | {"lastSuccessReportTabletsTime":"2025-10-17 04:23:48"} | 75.850 GB         | 0.00 %      | 8        | 6.207GB  | 0                 | 2.89 %     | 0.0 %      | Status: Normal, DiskUsage: 0B/0B, MemUsage: 0B/0B |          |
   | 10001     | kube-celerdata-be-2.kube-celerdata-be-search.default.svc.cluster.local | 9050          | 9060   | 8040     | 8060     | 2025-10-17 03:05:43 | 2025-10-17 04:24:39 | true  | false                | false                 | 42        | 0.000 B          | 75.850 GB     | 182.280 GB    | 58.39 % | 58.39 %        |        | 3.3.10-227b0b3 | {"lastSuccessReportTabletsTime":"2025-10-17 04:23:48"} | 75.850 GB         | 0.00 %      | 8        | 6.207GB  | 0                 | 2.88 %     | 0.1 %      | Status: Normal, DiskUsage: 0B/0B, MemUsage: 0B/0B |          |
   | 10004     | kube-celerdata-be-3.kube-celerdata-be-search.default.svc.cluster.local | 9050          | 9060   | 8040     | 8060     | 2025-10-17 03:05:43 | 2025-10-17 04:24:39 | true  | false                | false                 | 42        | 0.000 B          | 75.850 GB     | 182.280 GB    | 58.39 % | 58.39 %        |        | 3.3.10-227b0b3 | {"lastSuccessReportTabletsTime":"2025-10-17 04:23:48"} | 75.850 GB         | 0.00 %      | 8        | 6.207GB  | 0                 | 2.89 %     | 0.2 %      | Status: Normal, DiskUsage: 0B/0B, MemUsage: 0B/0B |          |
   | 10005     | kube-celerdata-be-4.kube-celerdata-be-search.default.svc.cluster.local | 9050          | 9060   | 8040     | 8060     | 2025-10-17 03:05:43 | 2025-10-17 04:24:39 | true  | false                | false                 | 41        | 0.000 B          | 75.850 GB     | 182.280 GB    | 58.39 % | 58.39 %        |        | 3.3.10-227b0b3 | {"lastSuccessReportTabletsTime":"2025-10-17 04:23:48"} | 75.850 GB         | 0.00 %      | 8        | 6.207GB  | 0                 | 2.89 %     | 0.1 %      | Status: Normal, DiskUsage: 0B/0B, MemUsage: 0B/0B |          |
   | 10312     | kube-celerdata-be-5.kube-celerdata-be-search.default.svc.cluster.local | 9050          | 9060   | 8040     | 8060     | 2025-10-17 04:13:24 | 2025-10-17 04:24:39 | true  | true                 | false                 | 0         | 0.000 B          | 75.850 GB     | 182.280 GB    | 58.39 % | 58.39 %        |        | 3.3.10-227b0b3 | {"lastSuccessReportTabletsTime":"2025-10-17 04:24:26"} | 75.850 GB         | 0.00 %      | 8        | 6.207GB  | 0                 | 2.85 %     | 0.2 %      | Status: Normal, DiskUsage: 0B/0B, MemUsage: 0B/0B |          |
   +-----------+------------------------------------------------------------------------+---------------+--------+----------+----------+---------------------+---------------------+-------+----------------------+-----------------------+-----------+------------------+---------------+---------------+---------+----------------+--------+----------------+--------------------------------------------------------+-------------------+-------------+----------+----------+-------------------+------------+------------+---------------------------------------------------+----------+
   ```

5. Execute the `ALTER SYSTEM DROP BACKEND` command to drop the decommissioned BE node from the CelerData cluster.

   ```sql
   ALTER SYSTEM DROP BACKEND "kube-celerdata-be-5.kube-celerdata-be-search.default.svc.cluster.local:9050"
   ```

6. Adjust the `replicas` field to a smaller number, e.g. 6-->5.
7. Repeat the above steps to remove other BE nodes until the desired number of BE nodes is reached.

## Why decommissioning first matters

Having run through it, here is what the extra steps buy you.

The operator does not implement CelerData's documented scale-in procedure. When you lower
`replicas`, it does one thing: it lowers `replicas` on the StatefulSet. Kubernetes then
deletes the highest-ordinal pods right away. Nothing tells the cluster those nodes are
leaving, so no one redistributes their tablets first — and in a `shared-nothing` cluster the
data lives on the nodes, so whatever was only on them is gone.

`ALTER SYSTEM DECOMMISSION BACKEND` is what makes the difference. It tells the cluster to
move that node's tablets elsewhere while the node is still running and reachable. Waiting
for `TabletNum` to reach 0 is how you know the move finished; that is why the procedure has
you re-run `SHOW BACKENDS` and check rather than proceeding on a timer. Only once the node
holds nothing is deleting its pod safe.

Setting `drop_backend_after_decommission` to `false` keeps the node registered after it
drains, so you can verify the drain before committing. With the default, the cluster drops
the node itself and you lose the chance to check.

**Why the recovery works at all:** the operator deletes pods but leaves their
PersistentVolumeClaims behind. Raising `replicas` back to the original count gives
Kubernetes the same pod names, which bind to those same surviving PVCs, and the data comes
back with them. That is a safety net rather than a design — it fails if the PVCs were
reclaimed, or if the cluster has already rebalanced around the loss. Do not rely on it.

Shared-data clusters are not affected, because the data is in object storage rather than on
the nodes. For the FE side of this and the broader picture, see
[Scaling behavior](../../explanation/scaling-behavior.md).
