# anywhere

The **only supported way to install PhoenixAI Anywhere** — a read-only operations & usage console
for PhoenixAI deployments on Kubernetes. Anywhere deploys **standalone, next to the PhoenixAI
operator** (its own single-replica StatefulSet with a data PVC, Service and ServiceAccount).

This chart is a subchart of the parent `kube-anywhere` chart (which also installs the operator
and a PhoenixAI cluster). Two ways to install it:

1. **With the parent chart** (recommended): set `anywhere.enabled=true` and prefix every value
   below with `anywhere.` (e.g. `anywhere.dependencies.s3.bucket`).
2. **Standalone** — from the released `anywhere-<version>.tgz` package, or from the
   `charts/anywhere/` directory of an unpacked `kube-anywhere` chart; use this next to an
   operator that is installed and managed separately. The values below apply as-is (no
   `anywhere.` prefix) and `enabled` is ignored.

## Prerequisites

- The operator installed with its gRPC query API exposed (`phoenixAIOperator.enableApiServer`,
  **on by default**; through the parent chart the key is
  `operator.phoenixAIOperator.enableApiServer`). This renders the `kube-anywhere-api` Service
  (`:9090`) that anywhere's ops data path talks to; the default `operatorApiAddrs` entry assumes
  the same namespace and the operator chart's default `nameOverride`.

## Install

**Object storage is required**: the chart refuses to render until `dependencies.s3` is configured
(see [External dependencies](#external-dependencies-s3--prometheus)).

Installation goes through a values file you author — `my-values.yaml` below — rather than `--set`
chains: the file is reviewable, reusable across upgrades, and the S3 block carries credentials
you do not want in shell history.

With the parent chart, in one install together with the operator and cluster:

```yaml
# my-values.yaml (the operator's gRPC query API is on by default)
anywhere:
  enabled: true
  dependencies:
    s3:
      bucket: <bucket>
      region: <region>
      accessKey: <ak>
      secretKey: <sk>
```

```bash
helm upgrade --install phoenixai phoenixai/kube-anywhere -n <namespace> -f my-values.yaml
```

Standalone, next to an operator you install and manage separately — the chart is published as its
own `anywhere` package, and the same keys apply without the `anywhere.` prefix:

```yaml
# my-values.yaml
dependencies:
  s3:
    bucket: <bucket>
    region: <region>
    accessKey: <ak>
    secretKey: <sk>
```

```bash
helm upgrade --install anywhere phoenixai/anywhere -n <namespace> -f my-values.yaml
```

The same chart also ships inside the parent package, so `helm pull phoenixai/kube-anywhere --untar`
followed by installing its `charts/anywhere/` directory is equivalent.

Then reach the console:

```bash
kubectl -n <namespace> port-forward svc/anywhere 8090:8090
curl -s localhost:8090/api/v1/health
```

## Scope: pairing the operator's mode

One anywhere serves every operator it is pointed at:

| Operator mode | Install | RBAC rendered |
|---|---|---|
| Global (default) | one anywhere for the whole Kubernetes cluster | ClusterRole + ClusterRoleBinding |
| Namespaced | one anywhere for ALL operators: list every operator API in `operatorApiAddrs` and every namespace in `watchNamespaces` | Role + RoleBinding per entry of `watchNamespaces` |

```yaml
# in my-values.yaml — namespaced-mode pairing: one anywhere, two operators
# (prefix both keys with `anywhere.` when installing through the parent chart)
operatorApiAddrs:
  - kube-anywhere-api.ns-a:9090
  - kube-anywhere-api.ns-b:9090
watchNamespaces:
  - ns-a
  - ns-b
```

Both values are plain lists — a single namespaced-mode operator is just one entry in each (the
one-anywhere-per-namespace install remains possible, it is just no longer required).

The RBAC is minimal and read-oriented: `secrets: [get]` (per-cluster credential resolution) and
`pods/exec: [create]` (the exec feature). Pod topology comes from the operator API, so no other
Kubernetes verbs are granted. The ServiceAccount and (Cluster)Role/(Cluster)RoleBinding are
always rendered — anywhere cannot function without them, so there is no `rbac.create`-style
toggle; what IS configurable is the ServiceAccount's name/annotations/labels (`serviceAccount.*`,
e.g. for cloud IAM bindings).

## External dependencies (S3 / Prometheus)

Anywhere is stateless by design — persistence and metrics come from services **the user provides**:

| Dependency | Consumed by | Values block |
|---|---|---|
| S3-compatible object storage (**required**) | large artifacts: query profiles (tens of KB–tens of MB) and support bundles (up to 100 GiB scale) | `dependencies.s3` |
| Prometheus (optional) | the System Monitoring pages (query-only, no own TSDB) | `dependencies.prometheus` |

There is deliberately no relational-database dependency: anywhere embeds its relational storage
(SQLite on the data PVC, sized by `persistence.size` — see [Persistence](#persistence)) — the
usage-metering ledger and future console state need no user-provided database.

`dependencies.s3` has no on/off switch — the chart refuses to render until `bucket` (and the
credentials your provider requires) are set, and at startup the backend re-enforces the same
policy and additionally probes the bucket (a write/read/delete of `system/startup-probe`), so bad
credentials or a missing bucket fail the pod immediately instead of silently mis-storing data. All
artifacts share one key layout — one top-level prefix per feature, optionally under `s3.path` (so
a bucket can be shared with other uses, e.g. the PhoenixAI cluster's own data bucket; `bucket`+`path`
match StarRocks' `aws_s3_path` semantics). It is inlined into the `dependencies:` section of the
rendered config-file Secret (`templates/secret-config.yaml` — the reason the config is a Secret
and not a ConfigMap). The whole config is read once at startup; changing any of it via
`helm upgrade` rolls the pod through the config checksum annotation, which is also how rotated
credentials take effect.

`dependencies.prometheus` stays opt-in (`enabled: false` by default):

```yaml
# in my-values.yaml, next to the required s3 block
dependencies:
  prometheus:
    enabled: true
    endpoint: http://prometheus.monitoring:9090
```

The Prometheus block supports the common enterprise access shapes — base URL with a path prefix,
basic auth or `bearerToken`, extra `headers` (multi-tenant `X-Scope-OrgID`), self-signed CA via
`tls.caCert` — plus two rename-adaptation knobs (`metricPrefix`, `clusterLabel`); see the comments
in [values.yaml](values.yaml). Validate the wiring after install with
`POST /api/v1/admin/dependencies/prometheus/check` — it checks config → connectivity → auth → metric
presence → rename detection → cluster label and answers each failure with actionable fix guidance.
The same checks also run per cluster as the `prometheus-dependency-unusable` health-check rule
(warning), so a missing or misconfigured dependency surfaces in the health-check view without anyone
opening that endpoint; an installation that deliberately runs without Prometheus can silence it via
`inspection.disabledRules`.

The S3 block is consumed by Query Insights History — query profile/explain/SQL texts land under
the `profile/` key prefix — and by Support bundles: bundle archives stream under the
`support-bundle/` prefix (no local staging, sized for 100 GiB-scale log collections), and can be
exported as presigned, expiring download URLs (`POST .../support/bundles/{id}/export`).
Operational notes:

- **Two-sided opt-in**: query-history collection is off by default on BOTH sides. Anywhere's own
  switch is `queryHistory.enabled` (chart value; off = anywhere sends no background requests to
  any cluster), matching the FE config `enable_collect_query_detail_info`, which also defaults to
  `false` — enable it at runtime with
  `ADMIN SET FRONTEND CONFIG ("enable_collect_query_detail_info" = "true")` (must reach every FE),
  persisted by also setting it in `fe.conf`. The PhoenixAI Database-side cost is a small in-FE-memory queue
  (~30s of query details, cleaned every 5s). The status endpoint
  (`GET /api/v1/namespaces/{ns}/clusters/{cluster}/query-history/status`) probes the flag and
  reports side-specific guidance, and the configuration inspection flags a half-enabled state
  (rule `query-detail-collect-inconsistent`).
- **What gets persisted**: only queries at least `queryHistory.slowQueryMs` (default 5000 ms) slow,
  plus every failed query; `slowQueryMs: 0` keeps everything but is suitable only for low-traffic
  clusters — at high QPS full persistence grows the database and object store without bound. See
  the sizing comment in `values.yaml`.
- **Retention**: anywhere deletes expired records and objects itself
  (query-history `retentionDays`, default 7; `supportBundle.retentionDays` for bundles —
  time is the primary dimension). Independent of retention, anywhere trims the oldest
  query-history records when the data PVC passes 85% usage, down to 70%. Configuring bucket
  lifecycle rules is a recommended backstop for
  objects orphaned while anywhere is down — expiration on the `profile/` prefix (query-history
  retention + 7 days) and on the `support-bundle/` prefix (bundle retentionDays + 7 days), plus an
  abort-incomplete-multipart-upload rule (a bundle upload killed mid-flight can leave paid-for
  parts behind).

## Persistence

The embedded relational storage (SQLite: the usage-metering ledger, future console state) lives
on a **standalone chart-managed PVC** named `data-<name>-0` (`data-anywhere-0` by default) —
deliberately not a StatefulSet `volumeClaimTemplate`, whose immutability would freeze the size at
install time:

- **Resize**: raise `persistence.size` in your values file and `helm upgrade -f my-values.yaml` to
  grow the volume in place, when the StorageClass has `allowVolumeExpansion: true`. Shrinking is
  rejected by Kubernetes. Some CSI drivers finish the filesystem expansion only on pod restart — if
  the PVC reports a `FileSystemResizePending` condition, `kubectl delete pod anywhere-0` completes
  it.
- **Survives uninstall**: the PVC carries `helm.sh/resource-policy: keep` — usage records are the
  customer's bill, remove them deliberately (`kubectl delete pvc data-anywhere-0`). A same-name
  reinstall adopts the kept PVC and its data.
- **Bring your own PVC**: set `persistence.existingClaim` to a pre-created claim in the release
  namespace; the chart then renders no PVC and `size`/`storageClass` are ignored.

## Notable values

Prefix each with `anywhere.` when installing through the parent `kube-anywhere` chart.

| Value | Default | Meaning |
|---|---|---|
| `enabled` | `false` | parent-chart condition: whether `kube-anywhere` installs the console (ignored standalone) |
| `image.repository` / `.tag` | the released console image, tag = chart appVersion | container image |
| `operatorApiAddrs` | `["kube-anywhere-api:9090"]` | ALL operator gRPC API Service addresses this anywhere serves — one entry per operator; order arbitrates ownership conflicts |
| `watchNamespaces` | `[]` (all namespaces, cluster-scoped RBAC) | the namespaces the PhoenixAI clusters live in when pairing namespaced-mode operators; one Role/RoleBinding each |
| `admin.users` / `admin.existingSecret` | `{}` / `""` (random single `admin` account) | Admin Console accounts — see the comments in `values.yaml` for the three sources and the GitOps caveat |
| `httpPort` | `8090` | HTTP listen/Service port |
| `logLevel` | `info` | debug/info/warn/error |
| `dependencies.s3.bucket` / `.region` / `.accessKey` / `.secretKey` / ... | `""` (required) | object storage for large artifacts — the chart refuses to render until this is configured, see [External dependencies](#external-dependencies-s3--prometheus) |
| `queryHistory.enabled` | `false` | query-history collection switch — off by default, matching the PhoenixAI Database-side `enable_collect_query_detail_info` default; enable both to use the history page |
| `queryHistory.slowQueryMs` | `5000` | persist bar in ms: only queries at least this slow are kept (failed queries always are); `0` keeps every query |
| `queryHistory.collectInterval` / `.retentionDays` | `10s` / `7` | sampling period (the FE queue retains only ~30s) and days to keep records + profile objects |
| `license.expiryWarnWindow` | `720h` (30 days) | how far ahead of a license's expiry warnings fire — the `license-invalid` inspection rule and the cluster list/overview `expiringSoon` flag share this boundary |
| `license.cacheTTL` | `5m` | how long a cluster's registered-license list is served from anywhere's in-memory cache before its FE is asked again; `"0s"` disables the cache |
| `inspection.enabledRules` / `.disabledRules` | `[]` / `[]` (all rules run) | CR-inspection rule selection; rule ids and meanings are listed as comments in `values.yaml` |
| `env` | `[]` | extra container env vars, e.g. `GODEBUG` (anywhere's own configuration is not env-settable — it goes through the rendered config file) |
| `serviceAccount.name` / `.annotations` / `.labels` | `""` (chart name) / `{}` / `{}` | the always-created ServiceAccount the pod runs as (annotations e.g. for cloud IAM bindings) |
| `persistence.size` | `10Gi` | data PVC size; growable via `helm upgrade` (StorageClass must allow expansion), never shrinkable |
| `persistence.storageClass` | `""` (cluster default) | StorageClass of the chart-rendered PVC |
| `persistence.existingClaim` | `""` | use a pre-created PVC instead of rendering one (`size`/`storageClass` then ignored) |

See `values.yaml` for the full list. Configuration reaches the container as a rendered config
file (the `anywhere-config` Secret — a Secret because the inlined `dependencies:` section
carries credentials — mounted and passed via `--config`); a checksum annotation on the pod
template rolls the pod whenever the rendered file changes. There are no `PHOENIXAI_ANYWHERE_*`
environment variables.
