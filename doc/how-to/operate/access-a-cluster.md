---
title: Access a cluster
sidebar_label: Access a cluster
sidebar_position: 1
description: Connect to a PhoenixAI cluster from inside Kubernetes, from outside via LoadBalancer or NodePort, or by port forwarding.
---

# Access a cluster

The components of the CelerData cluster can be accessed through their associated Services, such as the FE Service. For
detailed descriptions of Services and their access addresses,
see [api.md](https://github.com/celerdata/phoenixai-kubernetes-operator/blob/main/doc/api.md)
and [Services](https://kubernetes.io/docs/concepts/services-networking/service/).

The following table describes the FE Services of the CelerData cluster. `celerdatacluster-sample-fe-service` is the
Service that user can configure it from CelerDataCluster CR, and user should only use it to access the CelerData.
`celerdatacluster-sample-fe-search` is the internal Service that is used by CelerData Cluster to discover the FE nodes.

```bash
$ kubectl get svc
NAME                                 TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)                               AGE
celerdatacluster-sample-fe-search    ClusterIP   None           <none>        9030/TCP                              76s
celerdatacluster-sample-fe-service   ClusterIP   10.96.26.146   <none>        8030/TCP,9020/TCP,9030/TCP,9010/TCP   76s
```

## From inside the Kubernetes cluster

From within the Kubernetes cluster, the CelerData cluster can be accessed through the FE Service's ClusterIP.

1. Obtain the internal virtual IP address `CLUSTER-IP` and port `PORT(S)` of the FE Service.

    ```bash
    $ kubectl -n celerdata get svc 
    NAME                                 TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                               AGE
    celerdatacluster-sample-be-search    ClusterIP   None           <none>        9050/TCP                              66s
    celerdatacluster-sample-be-service   ClusterIP   10.96.86.207   <none>        9060/TCP,8040/TCP,9050/TCP,8060/TCP   66s
    celerdatacluster-sample-fe-search    ClusterIP   None           <none>        9030/TCP                              2m27s
    celerdatacluster-sample-fe-service   ClusterIP   10.96.26.146   <none>        8030/TCP,9020/TCP,9030/TCP,9010/TCP   2m27s
    ```

2. Access the CelerData cluster by using the MySQL client from within the Kubernetes cluster.

   ```bash
   mysql -h 10.100.162.xxx -P 9030 -uroot
   ```

   Upon deploying a fresh CelerData cluster, the `root` user's password remains unset, potentially posing a security
   risk. See [Change root user password HOWTO](../configure/change-root-password.md) for details on how to set
   the `root` user's password.

## From outside, with a LoadBalancer or NodePort

From outside the Kubernetes cluster, you can access the CelerData cluster through the FE Service's LoadBalancer or
NodePort. This topic uses LoadBalancer as an example:

1. Run the command `kubectl -n celerdata edit cdc celerdatacluster-sample` to update the CelerData cluster configuration
   file, and add `service` field to the `celerDataFeSpec` field.

    ```yaml
    spec:
      celerDataFeSpec:
        service:            
          type: LoadBalancer # specified as LoadBalancer
    ```

2. Obtain the IP address `EXTERNAL-IP` and port `PORT(S)` that the FE Service exposes to the outside.

    ```bash
    $ kubectl -n celerdata get svc
    NAME                                 TYPE           CLUSTER-IP       EXTERNAL-IP                                                              PORT(S)                                                       AGE
    celerdatacluster-sample-be-search    ClusterIP      None           <none>        9050/TCP                                                      6m39s
    celerdatacluster-sample-be-service   ClusterIP      10.96.86.207   <none>        9060/TCP,8040/TCP,9050/TCP,8060/TCP                           6m39s
    celerdatacluster-sample-fe-search    ClusterIP      None           <none>        9030/TCP                                                      8m
    celerdatacluster-sample-fe-service   LoadBalancer   10.96.26.146   a7509284bf3784983a596c6eec7fc212-618xxxxxx.us-west-2.elb.amazonaws.com     8030:30028/TCP,9020:32241/TCP,9030:32640/TCP,9010:32384/TCP   8m
    ```

3. Log in to your machine host and access the CelerData cluster by using the MySQL client.

    ```bash
    mysql -h a7509284bf3784983a596c6eec7fc212-618xxxxxx.us-west-2.elb.amazonaws.com -P9030 -uroot
    ```

## From outside, by port forwarding

From outside the Kubernetes cluster, you can access the CelerData cluster through the FE Service's port forwarding.

1. Make sure that you have installed the `kubectl` command-line tool and configured access to the Kubernetes cluster.
2. Run the command `kubectl -n celerdata port-forward service/celerdatacluster-sample-fe-service 9030:9030` to forward
   local port `9030` to FE Service's port `9030`.
3. Access the CelerData cluster by using the MySQL client.

    ```bash
    mysql -h 127.0.0.1 -P9030 -uroot
    ```
