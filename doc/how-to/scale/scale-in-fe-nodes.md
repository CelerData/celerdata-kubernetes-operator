---
title: Scale in FE nodes
sidebar_label: Scale in FE nodes
sidebar_position: 2
description: Remove FE nodes one at a time without breaking metadata quorum.
---

# Scale in FE nodes

FE nodes hold cluster metadata, so removing one is a deliberate, stepwise operation:
deregister the node from the cluster first, then reduce `replicas` by one, then repeat.

The steps come first below; [why it has to work this way](#why-one-node-at-a-time) is at the
end, once you have seen the procedure.

Two limits before you start:

- Never take more than the quorum offline in a single step. Going straight from 7 to 3 will
  not work; go 7 → 5, then 5 → 3.
- **3 → 1 always fails.** There is no way around this — see the explanation below.

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

## Why one node at a time

Now that you have run the procedure, here is what each step was protecting.

FE nodes store the cluster's metadata, and they agree on it through a quorum. If more than
half the nodes disappear at once, the survivors cannot form a majority and so cannot agree
on what the metadata is — the cluster stops accepting changes and can end up with
inconsistent state. Removing one node at a time keeps a majority intact at every moment,
which is why the procedure loops rather than letting you jump from 7 to 3.

Dropping the node with `ALTER SYSTEM DROP FOLLOWER` before touching `replicas` matters for
the same reason. The remaining FE nodes learn the node is gone deliberately, rather than
discovering a peer has vanished and waiting for it to come back. This is also why step 1
has you run `SHOW FRONTENDS` and confirm every node reports the same view: if they disagree
before you start, removing a node makes it worse.

The highest-ordinal-first rule is a Kubernetes detail rather than a database one. The
operator manages FE nodes as a StatefulSet, and lowering `replicas` on a StatefulSet always
removes the highest ordinal. Deregistering any other node would leave you with a
deregistered pod still running and a live node deleted.

**3 → 1 is the one case with no procedure.** Three nodes run as a BDBJE HA group, and one
node has to run as a single node; BDBJE cannot convert between the two modes on its own, so
the transition fails no matter how carefully you step through it. If you need a single-FE
cluster, deploy one.

For how this interacts with BE nodes, and the wider picture of what the operator does and
does not do on scale-in, see [Scaling behavior](../../explanation/scaling-behavior.md).
