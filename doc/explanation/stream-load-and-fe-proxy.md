---
title: Stream Load and the FE Proxy
sidebar_label: Stream Load and FE Proxy
sidebar_position: 6
description: Why Stream Load fails from outside the cluster network, what the FE Proxy fixes, and what it does not cover.
---

# Stream Load and the FE Proxy

## The problem

The issue is that when the load client residents in a different network other than FE/BE's private network. FE's HTTP
307 brings BE's private network address to the client who does not recognize and can't process the redirection.

## What the FE Proxy does

FE Proxy is a reverse proxy that can be used to solve this problem. It is a nginx server that listens on port 8080 and
proxies the HTTP request to FE and BE, including the HTTP 307 redirection.
> You need to switch the traffic, that is, the request sent to FE HTTP Port (8030) is sent to FE Proxy HTTP Port (8080).

## What the FE Proxy does not cover

**Note: FE proxy solves the data transfer link through HTTP protocol, non-HTTP traffic can't be proxied by the FE proxy
such as the spark connector reading data directly from BE nodes through thrift protocol.**

The following solutions for other read and write data scenarios are listed (will continue to be supplemented):

1. If you are unloading (reading) the data with the spark connector outside of k8s, a workaround
   is [INSERT INTO FILES](https://docs.starrocks.io/docs/unloading/unload_using_insert_into_files/), and then use spark
   to load data from the exported files.

For the procedure, see
[Load data with Stream Load](../how-to/operate/load-data-with-stream-load.md).
