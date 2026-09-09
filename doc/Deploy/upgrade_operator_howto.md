---
sidebar_label: Upgrade the operator
sidebar_position: 10
---

# Upgrade the Operator

This guide explains how to upgrade **only the operator** — the controller that reconciles the CRDs —
to a newer version. There are two paths, depending on how the operator was installed:

- **Path A — raw manifest / `kubectl`**: you `kubectl apply`-ed an `operator.yaml`.
  → apply the new CRDs, then update the operator image.
- **Path B — Helm**: you manage the operator through a Helm release.
  → apply the new CRDs, then `helm upgrade`.

It is **not** a data-plane (FE/CN) upgrade. To upgrade the StarRocks/PhoenixAI engine images, see
the "Upgrade PhoenixAI Cluster" section of
[Deploy PhoenixAI With Operator](./install_with_kubectl.md) and
[Deploy Warehouse](./deploy_warehouse_howto.md) instead.

The same procedure applies to the **community StarRocks operator** and the **PhoenixAI operator** —
they are the same chart family; only the names, registries, and values keys differ:

| | Community (StarRocks) | PhoenixAI |
| --- | --- | --- |
| Helm chart | `kube-starrocks` (or the `operator` subchart) | `kube-anywhere` (or the `operator` subchart) |
| Operator image | `starrocks/operator` | `…/enterprise/operator` |
| Operator values key | `starrocksOperator.*` | `phoenixAIOperator.*` |
| `operator.yaml` | StarRocks release — **bundles the CRDs** | PhoenixAI release — **CRDs shipped separately** |
| Helm repo | `https://starrocks.github.io/starrocks-kubernetes-operator` | `https://celerdata.github.io/phoenixai-kubernetes-operator` |

> Migrating from the community operator to PhoenixAI? PhoenixAI releases start at **v2.0.0**, whose
> CR/CRD schema baseline is community **v1.11.5**. First upgrade the **community** operator to
> v1.11.5 with this guide, confirm the cluster is healthy, then follow
> [Migrating from the open-source StarRocks operator to PhoenixAI](../Deploy/migrate-from-starrocks-howto.md).
>
> Running a **CelerData-era enterprise** operator (`kube-celerdata` release or `celerdata.com/v1`
> CRs, up to v1.11.5)? The same applies: there is **no in-place `helm upgrade`** to v2.0.0 — the
> chart, CRD group, and kinds were all renamed. Follow the same
> [migration guide](../Deploy/migrate-from-starrocks-howto.md); its converter auto-detects CelerData-era
> input, and your data and cluster identity are preserved.

## What an operator upgrade does (and does not do)

- It replaces only the **operator Deployment** — normally only the operator pod restarts.
- **In the common case it does not restart your FE/CN pods**: the data plane keeps serving and
  reconciliation only pauses for the few seconds the new operator takes to start.
- **It can, however, trigger a data-plane rolling restart.** If the new operator version renders the
  FE/CN StatefulSet pod template differently from the old one (e.g. a changed default, label,
  annotation, or env var), reconciliation updates the StatefulSet's pod template, and that rolls the
  affected FE/CN pods — a normal, one-pod-at-a-time StatefulSet rolling update. Check the release
  notes, and if a pod-template change is expected, plan the upgrade during a maintenance window.
- **You must apply the new CRDs yourself.** Each release usually adds new spec fields, but neither
  `helm upgrade` nor `kubectl set image` updates the CRDs — applying a newer operator without its CRDs
  leaves the new fields unrecognized. Applying a CRD is safe and does not disrupt running objects.
- You can **upgrade across versions directly** — there is no need to step through intermediate
  releases. Set `VERSION` to the target version and follow the path below.

The commands below use **upgrading to v2.0.0 as a concrete example** — replace `2.0.0` (and the
`VERSION` value) with your target version. Set these variables for your environment first:

```bash
VERSION=2.0.0              # the target operator version
OPNS=phoenixai             # the namespace the operator runs in
OP=kube-anywhere-operator  # operator Deployment name
                           # (older chart default: kube-phoenixai-operator;
                           #  community: kube-starrocks-operator)

# Not sure of the name/namespace? Find them:
kubectl get deploy -A | grep -E 'kube-(anywhere|phoenixai|starrocks)-operator'
helm list -A              # if Helm-managed, shows the release + its namespace
```

---

## Path A — raw `operator.yaml` / `kubectl`

Two steps: apply the new CRDs, then point the operator Deployment at the new image.

```bash
VERSION=2.0.0

# 1. Replace the CRDs (helm/kubectl never upgrade these automatically). Use `replace`, not `apply`:
#    `apply` copies the whole object into the kubectl.kubernetes.io/last-applied-configuration
#    annotation, which cannot exceed 262144 bytes. The PhoenixAICluster CRD is ~242 KB — under the
#    limit, but with less than 8% to spare, and only because these CRDs are generated with field
#    descriptions stripped (see the FAQ in install_with_kubectl.md). `replace` does
#    not write that annotation, so it never depends on that margin. The cluster CRD always exists
#    on an upgrade, so `replace` fits.
kubectl replace -f https://github.com/CelerData/phoenixai-kubernetes-operator/releases/download/v2.0.0/phoenixdata.ai_phoenixaiclusters.yaml

#    The warehouse CRD is the exception: operator charts only began shipping it in v2.0.0, and
#    `helm upgrade` never installs a chart's crds/, so on an operator upgraded from an earlier
#    version it does not exist yet and `replace` alone fails with NotFound. `create` first, fall
#    back to `replace`. At ~114 KB it is well clear of the annotation limit either way.
kubectl create -f https://github.com/CelerData/phoenixai-kubernetes-operator/releases/download/v2.0.0/phoenixdata.ai_phoenixaiwarehouses.yaml 2>/dev/null \
  || kubectl replace -f https://github.com/CelerData/phoenixai-kubernetes-operator/releases/download/v2.0.0/phoenixdata.ai_phoenixaiwarehouses.yaml

# 2. Update the operator image (container name is `manager`).
kubectl -n "$OPNS" set image deploy/"$OP" \
  manager=us-west1-docker.pkg.dev/phoenix-ai-images/enterprise/operator:v${VERSION}
kubectl -n "$OPNS" rollout status deploy/"$OP"
```

> Alternatively, re-apply the whole new `operator.yaml` instead of `set image` — do this if the new
> release also changed the operator's RBAC. First reconcile it with how your operator actually runs
> (namespace, resources, args, `imagePullSecrets`, …); the released manifest carries no customization.

---

## Path B — Helm

A Helm install of the operator is one of these two layouts — upgrade with the matching command:

```bash
# combined parent chart — operator + cluster in one release:
helm install <release> phoenixai/kube-anywhere -n <ns> ...
# or the operator subchart on its own (operator managed separately from clusters):
helm install <release> phoenixai/operator -n <ns> ...
```

Then upgrade in two steps: apply the new CRDs (Helm will not), then `helm upgrade`.

```bash
VERSION=2.0.0
helm repo update phoenixai            # or: helm repo update starrocks-community

# 1. Replace the CRDs (helm upgrade does NOT touch CRDs from a chart's crds/ directory). Use `replace`,
#    not `apply` — `apply` copies the whole object into the 262144-byte
#    kubectl.kubernetes.io/last-applied-configuration annotation, and the PhoenixAICluster CRD sits
#    at ~242 KB against that limit (see the FAQ in install_with_kubectl.md).
#    `replace` does not write that annotation. The cluster CRD already exists, so `replace` fits.
kubectl replace -f https://github.com/CelerData/phoenixai-kubernetes-operator/releases/download/v2.0.0/phoenixdata.ai_phoenixaiclusters.yaml

#    The warehouse CRD is the exception: operator charts only began shipping it in v2.0.0, and
#    `helm upgrade` never installs a chart's crds/, so on an operator upgraded from an earlier
#    version it does not exist yet and `replace` alone fails with NotFound. `create` first, fall
#    back to `replace`. At ~114 KB it is well clear of the annotation limit either way.
kubectl create -f https://github.com/CelerData/phoenixai-kubernetes-operator/releases/download/v2.0.0/phoenixdata.ai_phoenixaiwarehouses.yaml 2>/dev/null \
  || kubectl replace -f https://github.com/CelerData/phoenixai-kubernetes-operator/releases/download/v2.0.0/phoenixdata.ai_phoenixaiwarehouses.yaml

# 2. helm upgrade to the new chart version, re-passing the same values file you installed with
#    (use the chart you installed: kube-anywhere for combined, operator for the subchart).
helm upgrade <release> phoenixai/kube-anywhere --version "$VERSION" -n "$OPNS" -f your-values.yaml
kubectl -n "$OPNS" rollout status deploy/"$OP"
```

---

## Verify

Confirm the operator is on the new version, then confirm the cluster is unaffected:

```bash
kubectl -n "$OPNS" get deploy "$OP" -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'  # new version
kubectl -n "$OPNS" rollout status deploy/"$OP"                                                     # operator Running
```

An operator upgrade does not change cluster membership. Confirm the data plane the same way as in the
migration guide's [Verify](../Deploy/migrate-from-starrocks-howto.md#verify-both-paths) section (`SHOW FRONTENDS` / `SHOW BACKENDS` show the same nodes `Alive = true`).
