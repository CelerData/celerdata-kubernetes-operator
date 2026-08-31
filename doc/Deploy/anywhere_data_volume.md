---
title: The Anywhere data volume
sidebar_label: The Anywhere data volume
description: What Anywhere keeps on its own persistent volume, why it outlives an uninstall, and how to size it.
sidebar_position: 7
draft: true
---

# The Anywhere data volume

Anywhere keeps its own state on a persistent volume, separate from any cluster it manages.
[Back up and restore](../administration/management/Backup_and_restore.md) covers the data in a
PhoenixAI cluster. It does not cover this volume.

## What is on it

| Holds | Why it matters |
|---|---|
| Usage ledger | Append-only, tamper-evident record of metered usage. The basis of billing |
| Query history | Collected query records and their profiles, subject to the retention window |
| Saved commands and presets | Catalogue entries created in this deployment |
| Session snapshot | Written only during a graceful restart |

The usage ledger is the one thing here that cannot be reconstructed. It can be exported as a file
and kept independently of the volume — see the Usage page in the Anywhere Console.

Query history ages out on its own. Saved commands and exec presets persist until you delete them,
and would need re-creating if the volume were lost.

## It survives an uninstall

The volume is retained deliberately, so removing the release does not discard billing history. Its
name derives from the release name, so reinstalling under that same name reclaims it. Setting
`persistence.existingClaim` points Anywhere at a volume you name yourself instead.

## Sizing

Query history is what grows. Volume of retained records depends on workload and on the slow-query
threshold in force.

Two things trim it: the retention period, and a watermark that prunes the oldest records when the
volume runs low on space. Neither touches the usage ledger, which is never removed automatically.

Capturing every query on a cluster serving 100 queries per second produces millions of rows and
hundreds of gigabytes of query text per day. At the default threshold only slow and failed queries
are kept, which is a small fraction of that. The threshold and the retention period are the two
controls.

<!-- DOC NOTE: these figures are the current estimate, taken from the query-history feature notes
     rather than measured on a running deployment. Good enough to size against; worth revisiting
     once there is a real workload to check them with. -->
