---
title: Scale in FE nodes
sidebar_label: Scale in FE nodes
sidebar_position: 2
description: Remove FE nodes one at a time without breaking metadata quorum.
---

# Scale in FE nodes

FE nodes hold cluster metadata, so removing one is a deliberate, stepwise operation.
Read [Scaling behavior](../../explanation/scaling-behavior.md) first — in particular, never
remove more than the quorum allows in a single step, and note that 3 → 1 always fails.

If users want to scale in the FE nodes, they should:

1. Execute the `SHOW FRONTENDS` command to get the FE nodes information, and must choose the
   `kube-celerdata-fe-4.kube-celerdata-fe-search.default.svc.cluster.local` node with the highest ordinal to be removed
   first.

   ```sql
   mysql
   > show frontends;
   +-------------------------------------------------------------------------------------------+------------------------------------------------------------------------+-------------+----------+-----------+---------+----------+------------+------+-------+-------------------+---------------------+----------+--------+---------------------+----------------+
   | Name                                                                                      | IP                                                                     | EditLogPort | HttpPort | QueryPort | RpcPort | Role     | ClusterId  | Join | Alive | ReplayedJournalId | LastHeartbeat       | IsHelper | ErrMsg | StartTime           | Version        |
   +-------------------------------------------------------------------------------------------+------------------------------------------------------------------------+-------------+----------+-----------+---------+----------+------------+------+-------+-------------------+---------------------+----------+--------+---------------------+----------------+
   | kube-celerdata-fe-1.kube-celerdata-fe-search.default.svc.cluster.local_9010_1760648075561 | kube-celerdata-fe-1.kube-celerdata-fe-search.default.svc.cluster.local | 9010        | 8030     | 9030      | 9020    | FOLLOWER | 1931503630 | true | true  | 1646              | 2025-10-17 04:55:55 | true     |        | 2025-10-17 04:54:47 | 3.3.10-227b0b3 |
   | kube-celerdata-fe-0.kube-celerdata-fe-search.default.svc.cluster.local_9010_1760641496296 | kube-celerdata-fe-0.kube-celerdata-fe-search.default.svc.cluster.local | 9010        | 8030     | 9030      | 9020    | LEADER   | 1931503630 | true | true  | 1647              | 2025-10-17 04:55:55 | true     |        | 2025-10-17 03:05:04 | 3.3.10-227b0b3 |
   | kube-celerdata-fe-2.kube-celerdata-fe-search.default.svc.cluster.local_9010_1760648073373 | kube-celerdata-fe-2.kube-celerdata-fe-search.default.svc.cluster.local | 9010        | 8030     | 9030      | 9020    | FOLLOWER | 1931503630 | true | true  | 1646              | 2025-10-17 04:55:55 | true     |        | 2025-10-17 04:54:46 | 3.3.10-227b0b3 |
   | kube-celerdata-fe-3.kube-celerdata-fe-search.default.svc.cluster.local_9010_1760648073373 | kube-celerdata-fe-3.kube-celerdata-fe-search.default.svc.cluster.local | 9010        | 8030     | 9030      | 9020    | FOLLOWER | 1931503630 | true | true  | 1646              | 2025-10-17 04:55:55 | true     |        | 2025-10-17 04:54:46 | 3.3.10-227b0b3 |
   | kube-celerdata-fe-4.kube-celerdata-fe-search.default.svc.cluster.local_9010_1760648073373 | kube-celerdata-fe-4.kube-celerdata-fe-search.default.svc.cluster.local | 9010        | 8030     | 9030      | 9020    | FOLLOWER | 1931503630 | true | true  | 1646              | 2025-10-17 04:55:55 | true     |        | 2025-10-17 04:54:46 | 3.3.10-227b0b3 |
   +-------------------------------------------------------------------------------------------+------------------------------------------------------------------------+-------------+----------+-----------+---------+----------+------------+------+-------+-------------------+---------------------+----------+--------+---------------------+----------------+
   ```

2. Drop the FE node from the CelerData cluster.

   ```sql
   mysql> ALTER SYSTEM DROP FOLLOWER "kube-celerdata-fe-4.kube-celerdata-fe-search.default.svc.cluster.local:9010";
   Query OK, 0 rows affected (0.22 sec)
   ```

3. Adjust the `replicas` field to a smaller number, e.g. 5-->4.

4. Repeat the above steps to remove other FE nodes until the desired number of FE nodes is reached. 4-->3.
