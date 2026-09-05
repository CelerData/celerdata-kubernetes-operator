---
title: Reading a support bundle
sidebar_label: Reading a bundle
sidebar_position: 4
description: The five metadata files at the root of a bundle, what each answers, and the order to read them in.
---

# Reading a support bundle

Five files at the root of the archive describe the collection itself: whether it is complete, what
is missing and why, and what is safe to share. Read them before the collected data.

## The five files

| File | Answers |
|---|---|
| `bundle-info.json` | Which cluster, when, and the exact request — the time window, pods and files collected |
| `safety-report.txt` | What ran, and what the masking covered. Check this before forwarding a bundle |
| `collect-report.json` | Per-item result: collected, failed, or skipped — and why |
| `logs-manifest.tsv` | Source bytes against captured bytes for every file, so truncation is visible |
| `collect-audit.tsv` | Every upstream action with a timestamp and duration |

All five are always present.

## Read them in this order

1. **`bundle-info.json`** — confirm the cluster and especially the time window. If the window is
   wrong, nothing else in the bundle matters.
2. **`safety-report.txt`** — confirm which paths ran. If the bundle is leaving your organisation,
   this is also the compliance check.
3. **`collect-report.json`** — scan `failed` and `skipped` to learn what is missing and why, before
   concluding the data is not there.

   Each item has a status and a message. The message explains the status: a note on an item that
   succeeded, or the reason one failed or was skipped. Read the status first.

4. **`logs-manifest.tsv`** — before reading a log, confirm it is not truncated.
5. **`collect-audit.tsv`** — when you need to know how long a step took.

   This file records what ran, so skipped items never appear in it. To judge how much of the bundle
   was collected, use `collect-report.json` instead.

## Check a log is complete before reading it

A file can be cut short during collection, either because it was rotating or because collection hit
a limit. The archive still holds an entry of the declared size, padded with zeros, so the file looks
the right length and `wc -c` agrees.

If you search a log and find nothing, check `logs-manifest.tsv` before concluding the entry was
never written. Captured bytes lower than source bytes means the file is partial: widen the window
and collect again.

Search tools may refuse a padded file as binary. `grep -a` reads it anyway.

## Times in the metadata are UTC

The timestamps in these five files are UTC. Timestamps inside the collected logs are whatever the
node was set to. Convert before lining a bundle's timeline up against a log line, or the two will
appear hours apart.
