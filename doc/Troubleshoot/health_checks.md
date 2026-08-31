---
title: Health checks
sidebar_label: Health checks
sidebar_position: 1
description: What the health checks look for, how to read a finding, and where to see them.
draft: true
---

# Health checks

Health checks examine **how a cluster is configured**. They read the cluster and warehouse
definitions and report settings likely to cause trouble later.

They are not metrics: they report what is configured, not what is happening right now.

Most checks read only those definitions. Three do not: two read licence state from the cluster, and
one reports on Anywhere's connection to Prometheus. These three can fail or be skipped when the
cluster is unreachable, even if every other check passed.

## Reading a finding

Each finding names the check that produced it, the component it applies to, a severity, a status,
and a suggested fix.

**Severity:**

| Severity | Means |
|---|---|
| critical | Fix this |
| warning | Fix this |
| info | A judgment call — not following the advice is an acceptable trade-off |

> Info findings are not defects. Checks such as topology spread and serial pod management are
> recommendations. A cluster that ignores them can still be correctly configured.

**Status.** `skipped` is not `passed`:

| Status | Means |
|---|---|
| passed | Evaluated, and the configuration is fine |
| failed | Evaluated, and found a problem |
| skipped | Could not be evaluated — the finding says why |

Findings explain themselves. Each one names the check that produced it and what it looked for, and
a finding that failed or was skipped also carries why, and what to do about it. There is no separate
catalogue to consult.

A warehouse is checked against a subset of the list. A warehouse runs a single component, so the
checks that compare one component against another do not apply, and a warehouse reports fewer
findings than a cluster.

## Where to see them

In the console:

- **Health checks** — every cluster in one view, with a cluster selector
- On a single cluster, and on a single warehouse — the same findings, scoped

Or through the REST API, with an administrator session:

| Request | Returns |
|---|---|
| `GET /api/v1/admin/namespaces/{namespace}/clusters/{cluster}/inspections` | One cluster |
| `GET /api/v1/admin/namespaces/{namespace}/clusters/{cluster}/warehouses/{warehouse}/inspections` | One warehouse |
| `GET /api/v1/admin/inspections` | Every cluster in view; add `?namespace=` to narrow it |

## Turning checks off

Which checks run is set in Anywhere's configuration, under `inspection`: `enabledRules` turns the
catalogue into an allow-list, and `disabledRules` removes checks from whatever is left. Both are
read once at startup, so a change needs a restart.

The setting applies to the whole deployment, not to one cluster, and covers warehouse findings too.
Disabling a check silences it everywhere.

An id in either list that no longer exists in the catalogue is logged and skipped, so a
configuration written for an older build still starts.
