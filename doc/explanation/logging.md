---
title: Logging
sidebar_label: Logging
sidebar_position: 5
description: Why component logs disappear when a pod restarts, and the two ways to stop that happening.
---

# Logging

## The default storage volume

By default, all components use the `emptyDir` storage volume. One inherent problem is that once a Pod restarts, logs
before the restart will not be accessible anymore, which obviously complicates troubleshooting. To address this, one of
two approaches can be adopted:

1. Persist the logs so that logs from prior to the Pod restart remain available.
2. Log to the console and view logs from prior to the restart using `kubectl logs my-pod -p`.

The first option is durable but costs a volume per component; the second keeps logs in the
container runtime, where `kubectl logs` can reach them but only for the previous generation
of the pod.

For the procedures, see [Configure logging](../how-to/configure/configure-logging.md).
For the paths themselves, see [Log file locations](../reference/log-file-locations.md).
