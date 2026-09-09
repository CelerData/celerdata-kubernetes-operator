---
sidebar_label: Console data volume
sidebar_position: 6
title: The console data volume
description: What the Anywhere console keeps on its own persistent volume, why it outlives an uninstall, and how to size it.
---

# The console data volume

The Anywhere console keeps its own state on a persistent volume of its own, separate from any
cluster it manages and from the disks those clusters run on.
Backup and restore, in the PhoenixAI Database documentation, covers the data in a PhoenixAI
cluster. It does not cover this volume.

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

The volume is retained deliberately, so removing the release does not discard billing history.

Its name comes from the **chart**, not from your release name: `data-<anywhere.nameOverride>-0`,
which is `data-kube-anywhere-console-0` unless you override `anywhere.nameOverride`. Reinstalling
into the same namespace therefore reclaims it whatever you call the release. Setting
`persistence.existingClaim` points Anywhere at a volume you name yourself instead.

:::caution Reinstalling under a *different* release name needs `--take-ownership`
The claim is declared by the chart, so it carries Helm's ownership annotations from the release that
created it. Installing a release with a new name into a namespace that already holds the claim is
rejected before anything is applied:

```text
Error: unable to continue with install: PersistentVolumeClaim "data-kube-anywhere-console-0"
in namespace "phoenixai" exists and cannot be imported into the current release:
invalid ownership metadata; annotation validation error:
key "meta.helm.sh/release-name" must equal "kube-anywhere": current value is "phoenixai"
```

An installation made under an earlier release name — `phoenixai`, say — hits this the first time it
is reinstalled under the release name the current documentation uses, `kube-anywhere`. Hand the
existing claim to the new release:

```bash
helm upgrade --install kube-anywhere phoenixai/kube-anywhere \
  --namespace phoenixai -f my-values.yaml --take-ownership
```

Keeping the old release name works just as well, and changes nothing about the object names.
:::

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
