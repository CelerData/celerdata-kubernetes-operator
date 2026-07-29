---
title: Run a cluster locally
sidebar_label: Run a cluster locally
sidebar_position: 1
description: Build a single-node cluster on your own machine with kind and Helm, load a CSV file into it, and query the result.
---

# Run a cluster locally

In this tutorial you will build a working cluster on your own laptop — one FE node, one BE
node, and one FE Proxy — load a small CSV file into it, and query the result. It takes
about 20 minutes, and everything you create is thrown away at the end.

This is a learning exercise, not a production deployment. You will run a single replica of
each component with no persistent storage, which is exactly what you don't want in a real
cluster. Once you have the feel of it, the
[how-to guides](../how-to/install/deploy-with-helm.md) cover real deployments.

There is a fair amount of configuration in this document, and it is arranged with the step by
step content at the beginning and the technical details at the end. Follow the steps first and
watch it work; [what you just built](#what-you-just-built) explains the choices afterwards,
when you have something concrete to attach them to.

## What you need

| Resource | Minimum | Recommended |
| --- | --- | --- |
| CPU | 4 cores | 8 cores |
| Memory | 8 GB | 16 GB |
| Disk | 40 GB | 80 GB |

Install these four tools first. Each link goes to its own install instructions:

1. [Docker](https://docs.docker.com/get-docker/) — kind runs the Kubernetes cluster inside
   Docker containers. On macOS, [colima](https://github.com/abiosoft/colima) works too if
   you can't install Docker Desktop.
2. [kubectl](https://kubernetes.io/docs/tasks/tools/) v1.23 or later
3. [Helm](https://helm.sh/docs/intro/install/) v3.0 or later
4. [kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation) v0.20 or later

Check that all four are on your path:

```bash
docker version && kubectl version --client && helm version && kind version
```

Some familiarity with Kubernetes is assumed — enough to know what a pod and a namespace
are.

## Step 1: Create a Kubernetes cluster

You need to reach the cluster from your laptop, so tell kind to forward two ports out of
the container before it creates anything. Port 30001 will carry data loads, and port 30002
will carry SQL queries.

Write the kind configuration:

```bash
cat <<EOF > kind.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 30001
    hostPort: 30001
    listenAddress: "0.0.0.0"
    protocol: TCP
  - containerPort: 30002
    hostPort: 30002
    listenAddress: "0.0.0.0"
    protocol: TCP
EOF
```

Create the cluster:

```bash
kind create cluster --name celerdata --image kindest/node:v1.27.3 --config kind.yaml
```

Wait for the control plane to settle, then confirm every system pod is `Running`:

```bash
kubectl get pods -A
```

```text
NAMESPACE            NAME                                              READY   STATUS    RESTARTS   AGE
kube-system          coredns-64897985d-brlj9                           1/1     Running   0          4m26s
kube-system          coredns-64897985d-m9kj6                           1/1     Running   0          4m26s
kube-system          etcd-celerdata-control-plane                      1/1     Running   0          4m39s
kube-system          kindnet-jsrg8                                     1/1     Running   0          4m26s
kube-system          kube-apiserver-celerdata-control-plane            1/1     Running   0          4m39s
kube-system          kube-controller-manager-celerdata-control-plane    1/1     Running   0          4m39s
kube-system          kube-proxy-8h6b4                                  1/1     Running   0          4m26s
kube-system          kube-scheduler-celerdata-control-plane            1/1     Running   0          4m39s
local-path-storage   local-path-provisioner-5ddd94ff66-9l2km           1/1     Running   0          4m26s
```

If some pods are still `Pending`, give it another minute — Docker is pulling images.

## Step 2: Add the Helm repository

```bash
helm repo add celerdata https://celerdata.github.io/phoenixai-kubernetes-operator
helm repo update celerdata
```

## Step 3: Write the cluster configuration

The `kube-celerdata` chart installs the operator and a cluster together. Its defaults ask
for more CPU and memory than a laptop has, so you will override the resource requests and
attach the two NodePorts you mapped in step 1.

```bash
cat <<EOF > values.yaml
celerdata:
  celerDataFeSpec:
    resources:
      limits:
        cpu: 2
        memory: 4Gi
      requests:
        cpu: 500m
        memory: 1Gi
    service:
      type: NodePort
      ports:
      - name: query
        containerPort: 9030
        nodePort: 30002
        port: 9030
  celerDataBeSpec:
    resources:
      limits:
        cpu: 2
        memory: 4Gi
      requests:
        cpu: 500m
        memory: 1Gi
  celerDataFeProxySpec:
    enabled: true
    resources:
      requests:
        cpu: 100m
        memory: 200Mi
    service:
      type: NodePort
      ports:
      - name: http-port
        containerPort: 8080
        nodePort: 30001
        port: 8080
EOF
```

Two things to notice. First, this file sets no image tags — the chart's own defaults are
the images recommended for this release, so leave them alone. Second,
`celerDataFeProxySpec` is enabled: the FE Proxy is what lets you load data from your
laptop, which would otherwise fail. [Stream Load and the FE
Proxy](../explanation/stream-load-and-fe-proxy.md) explains why.

## Step 4: Install the cluster

```bash
helm install celerdata celerdata/kube-celerdata \
  --namespace celerdata --create-namespace \
  --values values.yaml
```

Watch the pods come up. This takes a few minutes:

```bash
kubectl -n celerdata get pods --watch
```

Press `Ctrl-C` once all four pods report `Running` and `1/1` ready:

```text
NAME                                      READY   STATUS    RESTARTS   AGE
kube-celerdata-be-0                       1/1     Running   0          2m
kube-celerdata-fe-0                       1/1     Running   0          3m
kube-celerdata-fe-proxy-5c7c7fc7b-wwvs6   1/1     Running   0          3m
kube-celerdata-operator-7498c7fbd-qsbgb   1/1     Running   0          3m
```

You now have a running cluster.

## Step 5: Create a table

Open a MySQL shell inside the FE pod. The image already contains a client, so you don't
need one on your laptop:

```bash
kubectl -n celerdata exec -it kube-celerdata-fe-0 -- \
  mysql -h 127.0.0.1 -P 9030 -uroot
```

At the `mysql>` prompt, create a database and a table:

```sql
CREATE DATABASE test_db;
USE test_db;

CREATE TABLE `table1`
(
    `id`    int(11)         NOT NULL COMMENT "user ID",
    `name`  varchar(65533)  NULL     COMMENT "user name",
    `score` int(11)         NOT NULL COMMENT "user score"
)
ENGINE=OLAP
PRIMARY KEY(`id`)
DISTRIBUTED BY HASH(`id`)
PROPERTIES ("replication_num" = "1");
```

`replication_num` is 1 because you have exactly one BE node. Leave the shell open — you
will come back to it in step 7.

## Step 6: Load a CSV file

Open a second terminal, **on your laptop this time**, not inside the pod. Create a small
CSV file:

```bash
cat <<EOF > example1.csv
1,Lily,23
2,Rose,23
3,Alice,24
4,Julia,25
EOF
```

Send it to the cluster with Stream Load. The request goes to port 30001 — the FE Proxy:

```bash
curl --location-trusted -u root: \
    -H "label:load-example-1" \
    -H "Expect:100-continue" \
    -H "column_separator:," \
    -H "columns: id, name, score" \
    -T example1.csv \
    -XPUT http://localhost:30001/api/test_db/table1/_stream_load
```

A successful load returns JSON with `"Status": "Success"` and `"NumberLoadedRows": 4`:

```json
{
    "TxnId": 1,
    "Label": "load-example-1",
    "Status": "Success",
    "NumberTotalRows": 4,
    "NumberLoadedRows": 4,
    "NumberFilteredRows": 0
}
```

Each load needs a unique `label`. If you run this a second time, change it — a repeated
label is how the cluster recognises and rejects a duplicate load.

## Step 7: Query the data

Back in the MySQL shell from step 5:

```sql
SELECT * FROM test_db.table1 ORDER BY id;
```

```text
+------+-------+-------+
| id   | name  | score |
+------+-------+-------+
|    1 | Lily  |    23 |
|    2 | Rose  |    23 |
|    3 | Alice |    24 |
|    4 | Julia |    25 |
+------+-------+-------+
4 rows in set (0.01 sec)
```

That is the whole loop: a cluster built from a chart, data pushed in through the proxy from
outside Kubernetes, and a query reading it back. Type `exit` to leave the shell.

## Step 8: Clean up

Delete the Kubernetes cluster, and with it everything you created:

```bash
kind delete cluster --name celerdata
```

That removes the containers, the cluster, and the data. To keep the Kubernetes cluster but
remove only the database, run `helm uninstall celerdata -n celerdata` instead.

## What you just built

You have a working cluster and a query returning rows. Now the parts worth understanding.

### The two ports, and why kind needed configuring

A `kind` cluster runs inside a Docker container, so its NodePorts are not reachable from your
machine unless you forward them when the cluster is created — which is why step 1 came before
everything else and cannot be added later without recreating the cluster.

You forwarded two, and used both for different things:

- **30002 → FE 9030**, the MySQL protocol port. This is the query path.
- **30001 → FE Proxy 8080**, the HTTP path. This is the load path.

### Why the load went through the FE Proxy

Step 6 sent the CSV to port 30001, not to FE. Stream Load is a two-hop protocol: you POST to
FE, and FE replies with an HTTP 307 redirect naming the BE that should receive the data. The
address in that redirect is the BE's address *on the cluster's internal network*.

From your laptop, that address does not resolve — so a direct Stream Load to FE fails after
appearing to start. The FE Proxy is an nginx reverse proxy that follows the redirect from
inside the cluster, where the address does resolve, and hands you back a single reachable
endpoint. That is why `celerDataFeProxySpec.enabled: true` was in `values.yaml`, and why
`--location-trusted` is in the `curl` command: it permits the client to follow the redirect
with credentials attached.

This is also the one part of the local setup that is not a toy — you would configure the FE
Proxy the same way in production for any client outside the cluster network. See
[Load data with Stream Load](../how-to/operate/load-data-with-stream-load.md).

### Why `replication_num` is 1

By default a table keeps three replicas of each tablet across different BE nodes. You have
one BE node, so a request for three replicas can never be satisfied and the table would sit
unhealthy. Setting `replication_num` to 1 matches the storage to the cluster. In a real
cluster, leave it at the default — it is what survives losing a node.

### What makes this unsuitable for production

Three things, each fixed by a how-to guide:

- **No persistent storage.** Every component wrote to an `emptyDir`, which exists only as
  long as the pod. A restart would have lost the metadata, the data, and the logs — see
  [Mount a persistent volume](../how-to/configure/mount-persistent-volume.md).
- **No password on `root`.** Fine on a laptop, unacceptable anywhere else — see
  [Initialize the root password](../how-to/configure/initialize-root-password.md).
- **One FE node.** No metadata quorum, so no tolerance for losing it. Production clusters run
  three, and note that you cannot later shrink three back to one — see
  [Scaling behavior](../explanation/scaling-behavior.md).

The resource limits you set are also deliberately small enough for a laptop and too small for
real work. The chart's defaults are the starting point for a real cluster.

### The images you did not override

`values.yaml` set no image tags, only resources and services. That was intentional: the
chart's default images are the ones matched to its version, so overriding them is how you get
a component mismatch. Pin images when you have a reason to, not by habit.

## What next

You built this by hand to see each piece. There is also a script,
[`scripts/local-install.sh`](../../scripts/local-install.sh), that installs kubectl, Helm,
and kind, creates the kind cluster, and installs the chart in one go — useful once the
steps above hold no surprises.

For real deployments:

- [Deploy a cluster with Helm](../how-to/install/deploy-with-helm.md) or
  [with the operator](../how-to/install/deploy-with-operator.md)
- [Mount a persistent volume](../how-to/configure/mount-persistent-volume.md) — the
  cluster you just built stored everything in `emptyDir`, so a pod restart would have lost
  it
- [Initialize the root password](../how-to/configure/initialize-root-password.md) — `root`
  had no password here, which is fine on a laptop and nowhere else
- [Access a cluster](../how-to/operate/access-a-cluster.md) — LoadBalancer, NodePort, and
  port-forwarding
