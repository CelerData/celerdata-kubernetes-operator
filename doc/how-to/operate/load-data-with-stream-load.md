---
title: Load data with Stream Load
sidebar_label: Load data with Stream Load
sidebar_position: 3
description: Deploy the FE Proxy so external clients can load data into the cluster with Stream Load.
---

# Load data with Stream Load

To load data from a client outside the cluster's network, deploy the **FE Proxy** and send
your load requests to its HTTP port (8080) rather than the FE HTTP port (8030). Without it,
Stream Load from outside the cluster fails.

Deploy it with Helm or with the CR below; [why it is needed, and what it does not
cover](#why-the-fe-proxy-is-needed) is at the end — read that part before you assume it
fixes every client.

## Deploy Fe Proxy Using Helm

If you install CelerData with Helm, you can add the following configuration to the `values.yaml` file:

For `kube-celerdata` Helm chart:

```yaml
celerdata:
  celerDataFeProxySpec:
    enabled: true
    replicas: 1
    # set the resolver for nginx server, default kube-dns.kube-system.svc.cluster.local
    resolver: ""
    limits:
      cpu: 1
      memory: 2Gi
    requests:
      cpu: 1
      memory: 2Gi
    service:
      type: NodePort
      ports:
        - name: http-port   # fill the name from the fe proxy service ports
          containerPort: 8080
          nodePort: 30180
          port: 8080
```

For `celerdata` Helm chart:

```yaml
celerDataFeProxySpec:
  enabled: true
  replicas: 1
  # set the resolver for nginx server, default kube-dns.kube-system.svc.cluster.local
  resolver: ""
  limits:
    cpu: 1
    memory: 2Gi
  requests:
    cpu: 1
    memory: 2Gi
  service:
    type: NodePort
    ports:
      - name: http-port   # fill the name from the fe proxy service ports
        containerPort: 8080
        nodePort: 30180
        port: 8080
```

Please
see https://github.com/celerdata/phoenixai-kubernetes-operator/blob/main/helm-charts/charts/kube-celerdata/values.yaml
for more details about how to configure `celerDataFeProxySpec`.

## Deploy Fe Proxy Using CelerDataCluster CR

If you install CelerData with CelerDataCluster CR yaml, please see
[deploy_a_celerdata_cluster_with_fe_proxy.md](../../../examples/celerdata/deploy_a_celerdata_cluster_with_fe_proxy.yaml)

## Why the FE Proxy is needed

Stream Load is a two-hop protocol. You POST to an FE, and the FE replies with an HTTP 307
redirect pointing at the BE that should actually receive the data. Your client is expected to
follow that redirect — which is what `--location-trusted` in the `curl` examples is for.

The catch is the address in the redirect. FE hands back the BE's address **on the cluster's
internal network**. A client inside Kubernetes can reach it. A client on your laptop, or in
another VPC, cannot: the redirect points somewhere that does not exist from where you are
standing, and the load fails after the first hop appears to succeed.

The FE Proxy is an nginx reverse proxy in front of both tiers. Requests arrive on port 8080,
and it forwards them to FE and BE — including following the 307 itself, from inside the
network where those addresses resolve. Your client only ever talks to one reachable address.
That is also why switching traffic from 8030 to 8080 is not optional: point at 8030 and you
get the unusable redirect straight from FE.

**What it does not cover.** The FE Proxy handles HTTP. Anything that talks to BE nodes over
another protocol is unaffected — most notably the Spark connector, which reads from BE
directly over thrift. Deploying the FE Proxy will not make that work from outside the
cluster.

For reading data out under that constraint, the usual workaround is
[INSERT INTO FILES](https://docs.starrocks.io/docs/unloading/unload_using_insert_into_files/)
to export to object storage, then have Spark read the exported files. It trades a direct
connection for a staging step, but it crosses the network boundary over HTTP.
