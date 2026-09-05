---
title: Generating a support bundle
sidebar_label: Generating a bundle
sidebar_position: 3
description: What a support bundle collects, how to scope one, and what is and is not masked before you send it on.
---

# Generating a support bundle

A support bundle collects logs, configuration and diagnostics from one cluster into a single archive
you can hand to support. Collection is read-only, and one bundle is collected at a time.

## Estimate before you collect

A bundle can run to gigabytes. The estimate runs the same file selection the collector does, so the
size it reports is the size you will get. The duration is a lower bound; collection can take longer.
Estimate before committing to a wide time window.

## Start from a scenario

A scenario is a preset for a symptom. It selects the artifacts support usually asks for, so you do
not have to choose them one by one.

For example:

- **Compute node crash** gathers what it takes to triage a crash or a restart loop — output from
  the run before the crash, and the query that was in flight.
- **Query trace** follows a single query ID across the coordinator logs, and needs you to supply
  the ID.

Others exist, and the set grows over time. The console carries the current list with a description
of each; start there rather than from this page.

A scenario pre-selects a subset. It does not restrict what you can add, and everything it selects
can be changed.

## What gets collected

A bundle can include, among other things:

- **Cluster definition and configuration files** — how the cluster and its warehouses are set up
- **Log files and log search** — everything in the window, or only the lines matching a search
- **Diagnostic queries** — read-only queries describing cluster state, such as nodes and running jobs
- **Thread dumps and thread stacks** — what coordinators and compute nodes were doing at the moment
  of collection
- **Query audit analysis** — failed statements, and the heaviest queries in the window
- **Crash context and memory diagnostics** — evidence for one specific class of failure
- **Metrics snapshot** — the monitoring window, so support sees the same charts you do. It comes
  back empty if no Prometheus is wired to Anywhere, and nothing in the bundle says so — check
  the console's monitoring pages before collecting a bundle for anything performance-related

<!-- DOC NOTE: this list is an API contract, not a description of the console -- it comes from
     bundleCategories in the backend, served through bundle-options. Keep it in sync when an
     artifact is added or removed there.

     Two things to know if you extend it. The backend has no grouping or type field:
     BundleCategoryInfo is {Name, DisplayName, Description} and the list is flat, so any grouping
     is ours to maintain. And the API's list is not the console's -- the console shows logs and
     log-search as a single row where the API has two entries. Follow the API. -->

## Getting the archive

There are two ways to retrieve a finished bundle.

- **Download** — the archive comes back through your existing session. Use it when you want to look
  at the bundle yourself, or send it to support manually.
- **Export link** — a pre-signed URL with an expiry. Anyone holding the link can download the
  bundle, so treat it as a credential. Useful for sharing within your own network, or with support
  where outbound transfer is permitted by your policy.

Bundles are removed after 7 days.

## What is masked, and what is not

Credentials in manifests and configuration files are masked irreversibly.

> **Audit logs contain user SQL verbatim and are deliberately not masked.** Review a bundle before
> sending it outside your organisation.

Every bundle contains a `safety-report.txt` listing what ran and what the masking covered. It is
generated from the artifacts that executed, so it describes that bundle rather than the product in
general — see [Reading a support bundle](./read_support_bundle.md).
