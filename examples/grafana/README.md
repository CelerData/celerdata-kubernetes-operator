# Grafana dashboards for Kubernetes deployments

## PhoenixAI-Overview-kubernetes.json

Cluster overview — FE and compute-node health, JVM, query latency, transactions,
compaction, and per-node resource use.

Import it in Grafana with **Dashboards -> New -> Import**, paste the JSON, and
pick your Prometheus data source. It expects the labels the `kube-anywhere`
chart's ServiceMonitors apply, so `metrics.serviceMonitor.enabled` must be `true`
and the ServiceMonitors must actually be selected by your Prometheus — see the
`release` label note in doc/QuickStart.

Importing through the API rather than the UI? The datasource input is named
`PhoenixAI_Prometheus`; pass it under that name or the import fails with
`missing dashboard input variable`.

Adapted from the upstream StarRocks `Dashboard-All-Arch.json`
(https://releases.starrocks.io/resources/Dashboard-All-Arch.json).

### Label changes

1. **Cluster identity is `cluster`, not `job`.** Upstream keys every query on
   `job="$cluster_name"`, which suits a hand-written scrape config where one job
   is one cluster. Under the Prometheus Operator, `job` defaults to the *Service*
   name, so it is per-component (`<cluster>-fe-service`, `<cluster>-cn-service`)
   and a dashboard filtered on it shows one component at a time. The chart sets
   `cluster` explicitly via a static relabeling, so this uses that instead. That
   also makes it independent of whether `jobLabel` is configured.

2. **Compute nodes match `group=~"be|cn"`.** A shared-data cluster runs CN, not
   BE. CN emits `starrocks_be_*` metric *names* but the chart labels it
   `group="cn"`, so upstream's `group="be"` filters miss it entirely.

3. **Panels are titled "Compute Node", not "BE".** Every label on a CN target
   already says `cn` (`group`, `app.kubernetes.io/component`, `container`); only
   the panel titles said BE, which read as wrong on a shared-data cluster. Since
   the queries match `group=~"be|cn"` and serve both deployment shapes, the
   titles use the neutral term rather than swapping one component name for the
   other. Metric *names* are untouched — the CN binary genuinely emits
   `starrocks_be_*`, and renaming those would need `metric_relabel_configs` and
   would break the Anywhere console, which queries the canonical names.

4. **A `warehouse` variable scopes the compute-node picker.** Warehouse CNs carry
   the same `cluster` label and `group="cn"` as the cluster's own, so they
   otherwise blend together. Note the asymmetry: only warehouse CNs carry a
   `warehouse` label, so the picker lists the warehouses and `All`; the cluster's
   own CNs appear under `All` but cannot be selected on their own.

### Metric changes

Upstream references five things that do not exist in 4.1.4. These were found by
loading data and watching which panels stayed empty — an idle cluster cannot
distinguish a dead panel from a quiet one.

| Upstream reference | Status in 4.1.4 | Fix |
| --- | --- | --- |
| `starrocks_be_chunk_allocator_mem_bytes` | removed, no replacement | panel deleted |
| `starrocks_be_column_pool_mem_bytes` | removed, no replacement | panel deleted |
| `starrocks_be_pipe_driver_queue_len` | removed (target was already `hide: true`, so it never rendered) | target dropped — the panel already queries `starrocks_be_pipe_drivers` alongside it |
| `starrocks_be_clonerunning_threads` | removed | target dropped — the panel already queries `starrocks_be_clone_active_threads` alongside it |
| `starrocks_fe_job{type="STREAM_LOAD"}` | never emitted; `type` only takes `BROKER`, `INSERT`, `SPARK` | two panels repointed at the compute-node counters `starrocks_be_streaming_load_*` |

The stream-load case was the least obvious: the panels were not merely empty on
an idle cluster, they stayed empty through two successful stream loads, because
the FE does not report stream load through `starrocks_fe_job` at all. The
compute-node counters do — `starrocks_be_streaming_load_requests_total`,
`_bytes`, `_duration_ms`, and `_current_processing`.

Two legend formats were also corrected: one captioned a `starrocks_be_pipe_drivers`
series as `pipe_driver_queue_len`, and one used `{{backend}}` on
`starrocks_fe_max_tablet_compaction_score`, which carries no `backend` label, so
every series rendered unnamed. (The *other* `{{backend}}` legend, on Tablet
Distribution, is correct — that metric does carry the label, and it resolves to
the compute-node addresses, warehouse CNs included.)

### Coverage

Measured on a kind cluster (3 FE + 1 CN + 1 warehouse CN, 4.1.4-ee, shared-data
on MinIO) carrying real data — 446,656 rows stream-loaded, then ~217 QPS driven
across both warehouses — by evaluating every target expression in the JSON
against the live Prometheus with template variables resolved to real instance
values:

| | Expressions | Populated |
| --- | --- | --- |
| Upstream `Dashboard-All-Arch.json` | 299 | 89 (29%) |
| This file | 309 | **306 (99%)** |

The three that stay empty are correct: two count *down* nodes and one counts bad
disks, so they are empty when nothing is down and no disk has failed.

Reproduce the count by POSTing each `targets[].expr` to
`/api/v1/query` with `$cluster_name`, `$fe_master`, `$fe_instance`,
`$be_instance` and `$be_brpc_port` substituted for values from the live cluster.
Note that `$be_brpc_port` resolves to the *port* (`8060`), not the metric name —
its variable definition carries a regex that extracts it.
